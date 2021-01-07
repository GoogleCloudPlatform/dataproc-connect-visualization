#!/bin/bash

# Copyright 2020 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# 0.usage.sh <HTML_ANCHOR_ID> <SECTION> <FILE>

echo '------------'
echo 'Usage:'
echo '1. Open the hands-on tutorial:'
echo "   https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud#${1}"
echo "2. Make sure you are in section \"${2}\""
echo '3. Open this file in an editor and use the snippets to follow the step-by-step instructions:'
echo "   vi ${3} "
echo '------------'
