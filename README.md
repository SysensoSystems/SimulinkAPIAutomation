# SimulinkAPIAutomation

Helps to generate the Model Construction Simulink API codes for given Model or Subsystem.

---------------------------------------------------------------------------
Use Cases:
Here are few basic use cases of this function.
- During verification and validation of controller models, it is often necessary to create the test models with the use of MATLAB program.
This will help the developer to the generate the code of the test model that is created manually.
- Sharing the model to other user in terms of m-file!!!
- It can be improved further to generate version nutral Simulink model atleast for selected MATLAB releases.

Please add the entire folder into MATLAB path before launching Simulink.
---------------------------------------------------------------------------
GUI Version:
- Within the Simulink model window, the tool("Generate Simulink API") can be invoked by right-click context menu
or from the "File" menu.
- Context menu can be used to initiate Simulink APIs for the Subsystem.
- File menu can be used to initiate Simulink APIs for the model.
---------------------------------------------------------------------------
API/Command Version:
Syntax:
>> generateSimulinkAPI(systemName)
Prints the API for the given system in the command window.

>> generateSimulinkAPI(systemName,filename)
Writes the API for the given system in the specified file.

systemName - It can be a simulink model or the subsystem.

Example:
>> generateSimulinkAPI('sldemo_absbrake')
Prints the API for the 'sldemo_absbrake' in the command window.

>> generateSimulinkAPI('sldemo_absbrake','sample.m')
Writes the API for the 'sldemo_absbrake' in the file 'sample.m'.
If you run the sample.m file it will generate the sldemo_absbrake_API model which is same as sldemo_absbrake.

---------------------------------------------------------------------------
Developed by: Sysenso Systems, https://sysenso.com/

Contact: contactus@sysenso.com
