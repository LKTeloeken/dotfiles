import sys
import pyfiglet

def main():
    text = "TA PAGO"

    if len(sys.argv) >= 2:
        # pega a string passada como argumento
        text = sys.argv[1]
    
    # cria o ascii art
    ascii_art = pyfiglet.figlet_format(text, font="broadway")
    
    # imprime no terminal
    print(ascii_art)

if __name__ == "__main__":
    main()