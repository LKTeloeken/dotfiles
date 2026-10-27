// Display brightness for the bar.
//
//   brightness get                      {"builtin":81,"external":50} (missing keys: no such display)
//   brightness set builtin|external N   N in 0..100
//
// The built-in panel goes through DisplayServices (private, loaded at runtime).
// External monitors do not expose brightness to macOS at all, so they are
// driven over DDC/CI: the monitor's own control channel, reached on Apple
// Silicon through IOAVService I2C writes to address 0x37. Only the first
// external display is handled, which matches a one-monitor desk setup.

#include <ApplicationServices/ApplicationServices.h>
#include <IOKit/IOKitLib.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// --- built-in panel (DisplayServices) ---

typedef int (*get_brightness_fn)(CGDirectDisplayID, float*);
typedef int (*set_brightness_fn)(CGDirectDisplayID, float);

static get_brightness_fn ds_get;
static set_brightness_fn ds_set;

static bool load_display_services(void) {
  void* handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY);
  if (!handle) return false;
  ds_get = (get_brightness_fn)dlsym(handle, "DisplayServicesGetBrightness");
  ds_set = (set_brightness_fn)dlsym(handle, "DisplayServicesSetBrightness");
  return ds_get && ds_set;
}

static CGDirectDisplayID builtin_display(void) {
  CGDirectDisplayID ids[16];
  uint32_t count = 0;
  if (CGGetOnlineDisplayList(16, ids, &count) != kCGErrorSuccess) return 0;
  for (uint32_t i = 0; i < count; i++) {
    if (CGDisplayIsBuiltin(ids[i])) return ids[i];
  }
  return 0;
}

// --- external monitor (DDC/CI over IOAVService) ---

typedef CFTypeRef IOAVServiceRef;
extern IOAVServiceRef IOAVServiceCreateWithService(CFAllocatorRef allocator, io_service_t service);
extern IOReturn IOAVServiceReadI2C(IOAVServiceRef service, uint32_t chip, uint32_t offset, void* buffer, uint32_t size);
extern IOReturn IOAVServiceWriteI2C(IOAVServiceRef service, uint32_t chip, uint32_t offset, void* buffer, uint32_t size);

#define DDC_CHIP 0x37
#define DDC_HOST 0x51
#define DDC_DEST 0x6E
#define VCP_BRIGHTNESS 0x10
// Monitors need a moment between a request and its reply, and between writes.
#define DDC_WAIT_US 40000

static IOAVServiceRef external_service(void) {
  io_iterator_t iterator;
  if (IOServiceGetMatchingServices(kIOMainPortDefault,
                                   IOServiceNameMatching("DCPAVServiceProxy"),
                                   &iterator) != KERN_SUCCESS) {
    return NULL;
  }

  IOAVServiceRef found = NULL;
  io_service_t service;
  while (!found && (service = IOIteratorNext(iterator))) {
    CFStringRef location = IORegistryEntryCreateCFProperty(service, CFSTR("Location"), kCFAllocatorDefault, 0);
    if (location) {
      if (CFStringCompare(location, CFSTR("External"), 0) == kCFCompareEqualTo)
        found = IOAVServiceCreateWithService(kCFAllocatorDefault, service);
      CFRelease(location);
    }
    IOObjectRelease(service);
  }
  IOObjectRelease(iterator);
  return found;
}

static uint8_t ddc_checksum(uint8_t seed, const uint8_t* data, size_t length) {
  uint8_t sum = seed;
  for (size_t i = 0; i < length; i++) sum ^= data[i];
  return sum;
}

// Returns the current value scaled to 0..100, or -1 when the monitor does not
// answer (no DDC support, or DDC disabled in its OSD menu).
static int ddc_get(IOAVServiceRef service) {
  uint8_t request[4] = { 0x82, 0x01, VCP_BRIGHTNESS, 0 };
  request[3] = ddc_checksum(DDC_DEST ^ DDC_HOST, request, 3);

  for (int attempt = 0; attempt < 3; attempt++) {
    uint8_t reply[12] = { 0 };
    if (IOAVServiceWriteI2C(service, DDC_CHIP, DDC_HOST, request, sizeof(request)) != kIOReturnSuccess)
      continue;
    usleep(DDC_WAIT_US);
    if (IOAVServiceReadI2C(service, DDC_CHIP, 0, reply, sizeof(reply)) != kIOReturnSuccess)
      continue;
    // reply: src, length, 0x02 (VCP reply), result, vcp, type, max hi/lo, cur hi/lo
    if (reply[2] != 0x02 || reply[3] != 0x00 || reply[4] != VCP_BRIGHTNESS) continue;
    int max = (reply[6] << 8) | reply[7];
    int current = (reply[8] << 8) | reply[9];
    if (max <= 0) continue;
    return (current * 100 + max / 2) / max;
  }
  return -1;
}

static bool ddc_set(IOAVServiceRef service, int percent) {
  // Most monitors use a 0..100 range for brightness, so the value is sent as is.
  uint8_t request[6] = { 0x84, 0x03, VCP_BRIGHTNESS, (uint8_t)(percent >> 8), (uint8_t)(percent & 0xff), 0 };
  request[5] = ddc_checksum(DDC_DEST ^ DDC_HOST, request, 5);

  for (int attempt = 0; attempt < 2; attempt++) {
    if (IOAVServiceWriteI2C(service, DDC_CHIP, DDC_HOST, request, sizeof(request)) == kIOReturnSuccess)
      return true;
    usleep(DDC_WAIT_US);
  }
  return false;
}

// --- cli ---

static int clamp_percent(int value) {
  return value < 0 ? 0 : (value > 100 ? 100 : value);
}

int main(int argc, char** argv) {
  bool has_ds = load_display_services();
  CGDirectDisplayID builtin = has_ds ? builtin_display() : 0;

  if (argc >= 2 && strcmp(argv[1], "get") == 0) {
    printf("{");
    bool first = true;
    float level;
    if (builtin && ds_get(builtin, &level) == 0) {
      printf("\"builtin\":%d", clamp_percent((int)(level * 100.f + 0.5f)));
      first = false;
    }
    IOAVServiceRef service = external_service();
    if (service) {
      int value = ddc_get(service);
      if (value >= 0) printf("%s\"external\":%d", first ? "" : ",", value);
      CFRelease(service);
    }
    printf("}\n");
    return 0;
  }

  if (argc == 4 && strcmp(argv[1], "set") == 0) {
    int percent = clamp_percent(atoi(argv[3]));
    if (strcmp(argv[2], "builtin") == 0) {
      if (!builtin) return 1;
      return ds_set(builtin, percent / 100.f) == 0 ? 0 : 1;
    }
    if (strcmp(argv[2], "external") == 0) {
      IOAVServiceRef service = external_service();
      if (!service) return 1;
      bool ok = ddc_set(service, percent);
      CFRelease(service);
      return ok ? 0 : 1;
    }
  }

  fprintf(stderr, "usage: brightness get | brightness set builtin|external 0-100\n");
  return 2;
}
