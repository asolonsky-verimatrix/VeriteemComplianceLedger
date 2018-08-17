#! python
import traceback
import sys
import os
import argparse
import veriteem as vmx
import veriteemcomplianceledger as vtc


def main(argv):

    parser = argparse.ArgumentParser()
    parser.add_argument("-r","--reader",        help="verify reader access ", action="store_true")
    parser.add_argument("-t","--contributor",   help="verify contributor access ", action="store_true")

    path    = None

    args     = parser.parse_args()
    if args.path != None:
       path = args.path


    try:
       myConfig = vmx.Config(path)
       myConfig.LoadConfig()
    except:
       raise Exception("Site Configuration Not Specified")

    if args.reader == True:
       try:
           vreader = vtc.ReaderVerify(path)
       except:
           print ("Reader access verification fails")
           sys.exit

       try:
           if vreader.Verify() == False :
              sys.exit
           print("Reader Verification Succeeded")
           
  
if __name__ == "__main__":
  main(sys.argv)
