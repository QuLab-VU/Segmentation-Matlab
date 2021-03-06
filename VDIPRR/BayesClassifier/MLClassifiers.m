function [] = MLClassifiers(option,handles)
global classMat
global classLabel
global im_cell_id

if option == 1  
    %save([handles.expDir filesep 'Handles.mat'],'handles')
    classMat = zeros(1,32);
    classLabel = cell(0);
    im_cell_id = [0,0];
    CreateClassifier(handles);
    %Now Build a classifier

    msgbox('Good One!')

elseif option == 2
    %Add to existing classifier
    [filename, pathname] = uigetfile('*.mat','Select Classifier')
    load([pathname filesep filename]);
    if ~exist('classMat')
        msgbox('You did not select a file with classifier info!')
        return
    end
    CreateClassifier(handles)
else
    [filename, pathname] = uigetfile('*.mat','Select Classifier')
    if isequal(filename,0) || isequal(pathname,0)
       msgbox('You must select a file or click Create Classifier')
       return
    end
    load([pathname filesep filename]);

end

    %Now 
    
    
    
    

%http://www.mathworks.com/help/stats/fitcnb.html
%http://www.mathworks.com/help/stats/classificationnaivebayes-class.html




