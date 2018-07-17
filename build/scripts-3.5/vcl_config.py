#!/usr/bin/python3
import traceback
import sys
import os
import argparse
import veriteemcomplianceledger as vmx
import shutil

class ComplianceLedgerInstall():
      installPath = None

      def __init__(self):
           
          ComplianceLedgerInstall.installPath = ComplianceLedgerInstall.find_module_path()
           
          
      @classmethod
      def find_module_path(self):
          for path in sys.path:
              if path == os.getcwd() :
                 continue
              if os.path.isdir(path) and "veriteemcomplianceledger" in os.listdir(path):
                 return os.path.join(path, "veriteemcomplianceledger")
          return None


      @classmethod
      def copyFiles(self,src, dst):
          fileList = os.listdir(src)
          for file in fileList :
              srcFile = os.path.join(src,file)
              dstFile = os.path.join(dst,file)
              if os.path.isfile(srcFile) == True :
                 if os.path.isfile(dstFile) == True :
                    os.remove(dstFile)
                 shutil.copy(srcFile, dst)
 
      @classmethod
      def install(self, path):

          #
          #  Get the directory to copy the management programs to
          #
          while True:
             prompt  = "Enter directory for scripts installation [" + path + "] : "
             userDir  = input(prompt)
             if not userDir :
                userDir = path

             if os.path.isdir(userDir) == True :
                break;

             response = input("Directory does not exist. Create it? [Y] : ")
             if not response:
                response = "Y"

             if response.upper() == "Y":
                os.mkdir(userDir)
                break
          
          print("Copying assets from " + ComplianceLedgerInstall.installPath)
          pfile = os.path.join(ComplianceLedgerInstall.installPath , "AttachLedger.py")
          shutil.copy(pfile, userDir) 

          scripts = os.path.join(ComplianceLedgerInstall.installPath,"scripts")
          userDir = os.path.join(userDir,"scripts")
          ComplianceLedgerInstall.copyFiles(scripts,userDir)

def main(argv):

    parser = argparse.ArgumentParser()
    parser.add_argument("-p","--path",   help="configuration path")

    args = parser.parse_args()

    myConfig = ComplianceLedgerInstall()
    path = args.path
    if path is None:
       path = os.getcwd()
    myConfig.install(path)
    

if __name__ == "__main__":
  main(sys.argv)

