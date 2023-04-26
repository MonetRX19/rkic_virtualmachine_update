
import os
import argparse
import sys
import re


#
# get project root path, it's decided by checking if `root.txt` exists
#
def get_prj_root():
    prj_root = '.'
    for i in range(10):
        if os.path.exists(prj_root + '/root.txt'):
            return prj_root
        else:
            prj_root = prj_root + '/..'
    if i == 9:
        print("CAN NOT FIND PROJECT ROOT PATH")
        sys.exit()
        
prj_root = get_prj_root()
print("PRJ ROOT: " + prj_root)


#
# check single file
#
def check(f):
    print('Checking file: {}'.format(f))
    with open(f, 'r') as lines:
        lineno = 0
        for l in lines:
            lineno += 1
            if re.search(r'(TODO)', l):
                print('Error: +{} {}'.format(lineno, f))
                print('\t{}'.format(l))


def get_filelist(dir):
  Filelist = []

  for home,dirs,files in os.walk(dir):
    for filename in files:
      Filelist.append(os.path.join(home,filename))
  return Filelist


#
# get rtl files from cmdline, and call check() one by one
#
if __name__ == '__main__':
    # step1: get rtl dir name
    cmdline_parser = argparse.ArgumentParser()
    cmdline_parser.add_argument('-y', help='specify rtl dirs')
    args = cmdline_parser.parse_args()

    if args.y:
        rtl = args.y
    else:
        rtl = 'rtl'

	# step2: get project directory
    dep = get_prj_root()

	# step3: concat rtl path
    rtlbasedir = dep + os.sep + rtl

	# step4: list all rtl files and do check()
  #  rtlfiles = os.listdir(rtlbasedir)
    rtlfiles = get_filelist(rtlbasedir)
    for f in rtlfiles:
        absf = rtlbasedir + os.sep + f
        if os.path.isfile(absf):
            if re.search(r'\.s?v$', f):
                check(absf)

