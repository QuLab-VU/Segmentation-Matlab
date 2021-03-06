% The integer programming Shawn Garbett and Stephen Hummel worked on on
% 22MAY13 using the Roysam data and MATLAB.
%
M = [0.43, 0, 0, 0,0; ...
    0.09, 0, 0, 0, 0; ...
    0.08, 0, 0, 0, 0; ...
    0.08, 0, 0, 0, 0; ...
    0, 0.18, 0, 0, 0; ...
    0, 0.18, 0, 0, 0; ...
    0, 0.11, 0, 0, 0; ...
    0, 0, 0.42, 0, 0; ...
    0, 0, 0.10, 0, 0; ...
    0, 0, 0, 0.46, 0; ...
    0, 0, 0, 0, 0.44; ...
    0.02, 0, 0, 0, 0; ...
    0, 0.28, 0, 0, 0; ...
    0, 0, 0, 0.04, 0];

N = [0.43, 0, 0, 0,0, 0; ...
    0, 0.09, 0, 0, 0, 0; ...
    0, 0, 0.08, 0, 0, 0; ...
    0, 0, 0, 0, 0, 0.08; ...
    0, 0.18, 0, 0, 0, 0; ...
    0, 0, 0, 0, 0, 0.18; ...
    0, 0, 0.11, 0, 0, 0; ...
    0, 0, 0.42, 0, 0, 0; ...
    0, 0, 0, 0, 0, 0.10; ...
    0, 0, 0, 0.46, 0, 0; ...
    0, 0, 0, 0, 0.44, 0; ...
    0.02, 0.02, 0, 0, 0, 0; ...
    0, 0.28, 0, 0, 0, 0.28; ...
    0, 0, 0.04, 0, 0, 0.04];

v = [1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1];
b = [1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1];

L = [0.86; 0.18; 0.15; 0.16; 0.36; 0.35; 0.22; 0.84; 0.20; 0.87; 0.88; 0.07; 0.84; 0.12];


Z = [0.43, 0, 0, 0,0, 0.43, 0, 0, 0,0, 0; ...
     0.09, 0, 0, 0, 0, 0, 0.09, 0, 0, 0, 0; ...
     0.08, 0, 0, 0, 0, 0, 0, 0.08, 0, 0, 0; ...
     0.08, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.08; ...
     0, 0.18, 0, 0, 0, 0, 0.18, 0, 0, 0, 0; ...
     0, 0.18, 0, 0, 0, 0, 0, 0, 0, 0, 0.18; ...
     0, 0.11, 0, 0, 0, 0, 0, 0.11, 0, 0, 0; ...
     0, 0, 0.42, 0, 0, 0, 0, 0.42, 0, 0, 0; ...
     0, 0, 0.10, 0, 0, 0, 0, 0, 0, 0, 0.10; ...
     0, 0, 0, 0.46, 0, 0, 0, 0, 0.46, 0, 0; ...
     0, 0, 0, 0, 0.44, 0, 0, 0, 0, 0.44, 0; ...
     0.02, 0, 0, 0, 0, 0.02, 0.02, 0, 0, 0, 0; ...
     0, 0.28, 0, 0, 0, 0, 0.28, 0, 0, 0, 0.28 ; ...
     0, 0, 0, 0.04, 0, 0, 0, 0.04, 0, 0, 0.04];

B = 1.0*(Z > 0.0);

Y = bintprog(-L, transpose(B), v);