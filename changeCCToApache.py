#change license from Creative commons to Apache in the spotFindingSuite

#%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/

import os

def changeLicense():
	old='%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/\n'
	new='%\n% Copyright 2013 Scott Rifkin, Allison Wu\n'
	new=new+'% Licensed under the Apache License, Version 2.0 (the "License");\n'
	new=new+'% you may not use this file except in compliance with the License.\n'
	new=new+'% You may obtain a copy of the License at\n%\n'
	new=new+'% http://www.apache.org/licenses/LICENSE-2.0\n%\n'
	new=new+'% Unless required by applicable law or agreed to in writing, software\n'
	new=new+'% distributed under the License is distributed on an "AS IS" BASIS,\n'
	new=new+'% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n'
	new=new+'% See the License for the specific language governing permissions and\n'
	new=new+'% limitations under the License.\n%\n'
	fis=os.listdir('.')
	for i in fis:
		if i.endswith('.m'):
			fi=open(i,'r').read()
			if old in fi:
				fi=fi.replace(old,new)
				print 'old found in '+i
				ofi=open(i.replace('.m','.mapache'),'w')
				ofi.write(fi)
				ofi.close()
			else:
				print 'not old found in '+i
			
		 
		