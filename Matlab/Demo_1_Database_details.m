%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%
% Copyright 2019 Mohammad Al-Sa'd
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Authors: Mohammad F. Al-Sa'd (mohammad.al-sad@tuni.fi)
%          Amr Mohamed         (amrm@qu.edu.qa)
%          Abdulla Al-Ali
%          Tamer Khattab
%
% The following reference should be cited whenever this script is used:
%     M. Al-Sa'd et al. "RF-based drone detection and identification using
%     deep learning approaches: an initiative towards a large open source
%     drone database", 2019.
%
% Last Modification: 12-02-2019
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

close all; clear; clc
filename = 'G:\Data\';  % Path of raw RF data
format shortg

%% Parameters
BUI = {'00000','10000','10001','10010','10011','10100','10101','10110','10111','11000'};
N_seg = 1e7;

%% Counting
c = zeros(1,length(BUI));
for i = 1:length(BUI)
    c(1,i) = length(dir([filename char(BUI{i}) '*.*']));
end

%% Level 1 details
L1     = zeros(2,1);
L1(1)  = N_seg*sum(c(2:end));
L1(2)  = N_seg*c(1);
P1     = 100.*L1./sum(L1);

%% Level 2 details
L2     = zeros(4,1);
L2(1)  = N_seg*sum(c(2:5));
L2(2)  = N_seg*sum(c(6:9));
L2(3)  = N_seg*c(10);
L2(4)  = N_seg*c(1);
P2     = 100.*L2./sum(L2);

%% Level 3 details
L3     = zeros(10,1);
L3(1)  = N_seg*c(2);
L3(2)  = N_seg*c(3);
L3(3)  = N_seg*c(4);
L3(4)  = N_seg*c(5);
L3(5)  = N_seg*c(6);
L3(6)  = N_seg*c(7);
L3(7)  = N_seg*c(8);
L3(8)  = N_seg*c(9);
L3(9)  = N_seg*c(10);
L3(10) = N_seg*c(1);
P3     = 100.*L3./sum(L3);

%% Display
disp([L1/N_seg/2 L1 P1]);
disp([L2/N_seg/2 L2 P2]);
disp([L3/N_seg/2 L3 P3]);
