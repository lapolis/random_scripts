#! /usr/bin/python

# ALL the credits to WJDigby --> https://gist.github.com/WJDigby/acd41da3dc68a14a2ea3e2d5be871b60

# Requries at least Python 3.6
# Reads from stdin or file ( -i / --input-file), writes to stdout or file ( -o / --output-file)
# Supports XORing with provided key (-x / --xor)
# Supports output formats of C, C#, Java, VB, and B64 string ( -f / --format)
# Change shellcode output variable name with -n / --name

# Examples:
# Read shellcode from stdin, XOR with key 'secret!', format in C byte array, and write to file "sc.txt":
# python shellcode_utils.py -i - -x 'secret!' -f c -o sc.txt < shellcode.bin
# Read shellcode from file, format in Base64 string, change shellcode variable name to "not_shellcode":
# python shellcode_utils.py -i shellcode.bin -f b64 -n not_shellcode

import argparse
from collections import namedtuple
import codecs
import sys

def xor_sc(sc, key):
    """XOR shellcode with provided key of arbitrary length.
    Takes shellcode characters as bytes, returns XORed bytes.
    """

    xored_sc = []
    i = 0
    for sc_byte in sc:
        if i < len(key):
            xored_byte = sc_byte ^ key[i]
            xored_sc.append(xored_byte)
            i += 1
        else:
            xored_byte = sc_byte ^ key[0]
            xored_sc.append(xored_byte)
            i = 1
    return bytes(xored_sc)


def format_sc(sc, output_format):
    """Format the shellcode for pasting in C/C++, C#, Java, or Visual Basic projects.
    Takes shellcode as bytes, returns formatted bytes.
    """

    if output_format == 'b64':
        sc = split_sc(sc)
        return sc

    sc = ["{0:#0{1}x}".format(int(x),4) for x in sc] 

    CodeFormat = namedtuple('CodeFormat', 'open close heading items_per_line func')
    if output_format == 'c':
        cf = CodeFormat(open='{\n', close='\n};', heading=f'unsigned char shellcode[{len(sc)}] = ', items_per_line=12, func=None)
    elif output_format == 'c#':
        cf = CodeFormat(open='{\n', close='\n};', heading='byte[] shellcode = ', items_per_line=12, func=None)
    elif output_format == 'java':
        cf = CodeFormat(open='{\n', close='\n};', heading='byte shellcode[] = ', items_per_line=5, func=['(byte)' + x for x in sc])
    elif output_format == 'vb':
        cf = CodeFormat(open='{\n', close='\n}', heading='Dim shellcode As Byte() = ', items_per_line=12,
                        func=[x.replace('0x', '&H').upper() for x in sc])

    if cf.func:
        sc = cf.func

    iterations = (len(sc) // cf.items_per_line) if len(sc) % cf.items_per_line == 0 else (len(sc) // cf.items_per_line + 1)

    iteration = 0
    index = [0, cf.items_per_line]
    lines = []

    while iteration < iterations:
        line = ', '.join(sc[index[0]:index[1]])
        lines.append(line)
        index[0] = index[1]
        index[1] = index[1] + cf.items_per_line
        iteration += 1

    sc = ',\n'.join(lines)
    sc = cf.heading + cf.open + sc + cf.close

    return sc.encode()


def split_sc(sc, row_length=80):
    """Format shellcode for pasting into projects as series of concatenated Base64 strings.
    Takes shellcode as bytes, returns formatted base64 encoded bytes.
    """

    sc = codecs.encode(sc, 'base64').decode().replace('\n', '')
    base64_sc = ''
    index = [0, row_length - 1]
    for i in range((len(sc) // row_length) + 1):
        base64_sc += f'shellcode {"=" if index[0] == 0 else "+="} "{sc[index[0]:index[1]]}";\n'
        index[0] = index[1]
        index[1] = index[1] + row_length
    return base64_sc.encode()


def main():
    """XOR and format shellcode."""

    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input-file', type=argparse.FileType('rb'),
                        help='File containing shellcode or read from <stdin>')
    parser.add_argument('-o', '--output-file', type=argparse.FileType('wb'), default=sys.stdout,
                        help='Output file to write. Defaults to <stdout>.')
    parser.add_argument('-x', '--xor', type=str, help='XOR shellcode with key.')
    parser.add_argument('-f', '--format', type=str.lower, choices=['c', 'c#', 'vb', 'java', 'b64'],
                        help='Format the shellcode for including in C/C++ or C# projects.')
    parser.add_argument('-n', '--name', type=str, help='Name for the shellcode variable. Default "shellcode".')
    args = parser.parse_args()

    infile = args.input_file
    outfile = args.output_file
    key = args.xor
    output_format = args.format
    var_name = args.name

    if not infile:
        print('[-] Provide shellcode via -i/--input-file or stdin')
        exit()

    # Read shellcode from file or stdin into bytes
    sc = infile.buffer.read() if infile.fileno() == 0 else infile.read()

    if key:
        sc = xor_sc(sc, key.encode())

    if output_format:
        sc = format_sc(sc, output_format)

    if output_format and var_name:
        sc = sc.replace(b'shellcode', var_name.encode())

    # Select write method for writing to stdout or file
    sys.stdout.buffer.write(sc) if outfile.fileno() == 1 else outfile.write(sc)


if __name__ == '__main__':
    main()
