#!/bin/sh
#
#  This command loads the distribution to the pypi.org site for access via pip3 install veriteemcomplianceledger
#
#  You need and account on pypi.org and will be prompted for account/password to complete the operation
#
#  The version number of the upload is set in the setup.py file in this directory
# 
twine upload dist/*
