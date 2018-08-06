#!/usr/bin/env python
# Copyright (c) 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import atexit
import os
import sys
import shutil

from setuptools import setup
from setuptools import find_packages
from setuptools.command.install import install


setup(
    name="veriteemcomplianceledger",
    version="0.1.8",
    packages=find_packages('src'),
    package_dir={'':'src'},
    package_data={
         # include any asset files found in the 'Veriteem' package:
        'veriteemcomplianceledger': ['scripts/*' ],
    },

    scripts=['src/veriteemcomplianceledger/VeriteemCL.py'],
    install_requires=[
                      'veriteem'
                     ],


    # metadata for upload to PyPI
    author="Brad Ree",
    author_email="bree@verimatrix.com",
    description="Veriteem Compliance Ledger Client",
    license="GPL",
    keywords="Veriteem Compliance Ledger",
    url="http://www.veriteem.com/",   # project home page, if any
    project_urls={
        "Bug Tracker": "https://bugs.example.com/HelloWorld/",
        "Documentation": "https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki",
        "Source Code": "https://github.com/VerimatrixGen1/VeriteemComplianceLedger",
    }

    # could also include long_description, download_url, classifiers, etc.  
)
