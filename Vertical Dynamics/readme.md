# Virtual Half-Car Shaker Rig

### Run the model
The model is setup and ran with Matlab script "RunHalfCarModel.m" and others, where you can find input parameters. Dampers and springs are read with this script from excel tables. The default formatting of the tables are presented by the damper data from the damper table file, where the first row is damper velocity in mm/s, and the first column the damper settings marked as "clicks".

General Vehicle Parameters are currently in the Simulink model's "Car Parameters" block.

To run anything, add the "Vertical Dynamics" folder and all the sub-folders to Matlab path.

运行此半车模型前将 "Vertical Dynamics" 文件夹加入Matlab路径。仿真输入的避震曲线和弹簧曲线均由Excel表输入，第一行黄色输入为避震速度/位移,单位为mm/s，第一列为避震“档位”。其他车辆参数在Simulink模型中调整。


