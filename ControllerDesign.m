motorDynamics = xlsread('SingleMotorData.xlsx');
motorVoltage = motorDynamics ([3:11],1);%V
motorLift = motorDynamics ([3:11],2);%N
motorCurrent = motorDynamics ([3:11],3);%A
motorProp = motorDynamics ([3:11],4);%Rad/s
motorTorque = motorDynamics ([3:11],5);%N*m % Calculating Kf (Motor force-thrust constant)
c1=polyfit(motorVoltage,motorLift,1);
v1=polyval(c1,motorVoltage);

figure (1)
plot(motorVoltage,motorLift,'s',motorVoltage,v1);
grid on
title('Lift vs Voltage')
xlabel('Voltage [V]')
ylabel('Lift [N]')

text (9.5,.6442 , 'slope= Kf= 0.1242')

Kf=0.1242;

%Calculating Kmt (Motor-Torque Constant)
c2=polyfit(motorCurrent,motorTorque,1);
v2=polyval(c2,motorCurrent);
figure (2)
plot(motorCurrent,motorTorque,'s',motorCurrent,v2);
grid on
title('Torque vs Current')
xlabel('Current [A]')
ylabel('Torque [N*m]')

text (1.75,.035 , 'slope= Kmt= 0.0227')

Kmt=0.0227;

%Calculating Fw (Force-Speed Constant)
c3=polyfit(motorProp,motorLift,1);
v3=polyval(c3,motorProp);
figure (3)
plot(motorProp,motorLift,'s',motorProp,v3);
grid on
title('Lift vs Prop Speed')
xlabel('Prop Speed [rad/s]')
ylabel('Lift [N]')

text (450,.5 , 'slope= Fw= 0.029')

Fw=0.0029;

%Calculating Kb (Motor-Votage Constant)
c4=polyfit(motorProp,motorVoltage,1);
v4=polyval(c4,motorProp);
figure (4)
plot(motorProp,motorVoltage,'s',motorProp,v4);
grid on
title('Voltage vs Prop Speed')
xlabel('Prop Speed [rad/s]')
ylabel('Voltage [V]')
text (450,8.5 , 'slope= Kb=0.0237')

Kb=0.0237; % Givens
Rm = 0.83;
Jpm = 6.4516*10^-5;
Kpt = 1.2447*10^-4;
% Motor Transfer Function
MotorDyn=tf((Kmt*Fw),[0,(Rm*Jpm),((Kpt*Rm)+(Kmt*Kb))]) % Elevation Transfer Function
Mc=1.919;
Mh=1.464;
Lb=18.5*0.0254;
La=25.75*0.0254;
Lp=6.932*0.0254;
Je=1.05*((Mc*(Lb^2))+(Mh*(La^2)));
G3_elev=tf((La),[Je,0,0]);
Elevtf=MotorDyn*G3_elev % Pitch Transfer Function
Jp=1.05*(Mh*(La^2));
G3_pitch=tf((Lp),[Jp,0,0]);
Pitchtf=G3_pitch % Travel Transfer Function
g=9.81;
Jt=Je;
Keff=0.150*g;
G3_Trav=tf((-Keff*La),[Jt,0,0])
Ploop=PitchC_PID*Pitchtf
PitchL=Ploop/(1+Ploop)
Traveltf=PitchL*G3_Trav

%Elevation PID
%8.28%os, 6.29 TS, 0.418 RS
%Kp=16.9502 Ki=1.3722 Kd=54.9872
ElevC_PID=pid(16.9502, 1.3722, 54.9872);

figure (5)
rlocus(ElevC_PID*Elevtf)
title('Elevation Root Locus')

xlim([-1 1])
ylim([-1 1])

%Pitch PID
%5.19%os, 4.12 TS, 0.309 RS
%Kp=8.6935 Ki=1 Kd=22.7760
PitchC_PID=pid(8.6935, 1, 22.7760 );

figure (6)
rlocus(PitchC_PID*Pitchtf)
title('Pitch Root Locus')
xlim([-1 1])
ylim([-1 1])

%Travel PID
%8.63%os 9.46 TS .549 RS
%Kp=-6.0645 Ki=-0.0248 Kd=-3.3682

TravelC_PID=pid(-6.0645,-0.0248,-3.4731);

figure (7)
rlocus(TravelC_PID*Travelf)
title('Travel Root Locus')
xlim([-1 1])
ylim([-1 1])

%Trajectory Planning
TrajT=[0 5 10 15 20 25 30 35 40];
TrajE=[0 10 15 5 10 15 20 25 30];
TrajTr=[0 15 10 27 10 5 15 20 15];
time=linspace(0,40,20000);
s1=spline(TrajT,TrajE,time)
s2=spline(TrajT,TrajTr,time)
%velocity
pp = interp1(time,s1,'spline','pp')
pp_der=fnder(pp,1);
slopes=ppval(pp_der,time);
%accel
pp2 = interp1(time,slopes,'spline','pp')

pp_der2=fnder(pp2,1);
slopes2=ppval(pp_der2,time);
figure(5)
plot(time,s1);
hold on
plot(time,slopes);
plot(time,slopes2);
title('Trajectory Plan for Elevation')
xlabel('Time [sec]')
ylabel('Degrees')
xlim([0 20])
legend({'position','velocity','acceleration'},'Location','northwest')

%Trajectory Function Block
function Travelout = fcn(time,s2)
      persistent i
  persistent elevo
  if isempty(elevo)
    elevo=0;
    i=1;
  end
  if(time<40)
    elevo= s2(i);
    i=i+1;
  else
    elevo=0;
  end
Travelout= elevo;
