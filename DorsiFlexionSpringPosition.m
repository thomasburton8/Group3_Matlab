classdef DorsiFlexionSpringPosition
    properties
        Link1X
        Link1Y
        Link2X
        Link2Y
        Link3X
        Link3Y
       
        Length
        
        %% Percentages up and down the leg for the attachments       
        thighPulleyPercentDownThigh = 0.8;
        shankPullyPercentDownShank = 0.2;
        camPullyPercentDownShank = 0.6226; % its at the center line
        radiusOfPulley = 0.01111;
        
        radiusOfThePulley = 0.0087305; % This is a constant value - redefine the sim off this
        % upper plus, lower minus
        
        %% Distance Off Toe -- change with param
        distAboveToe = 0.02;
        
        %% Values used in solidworks
        pullyDistanceFromTheCenterLine
        
        %% Used to find moment contribution
        AppliedToeCableForceAngle
        distanceFromAnkle2ToeCableX
        distanceFromAnkle2ToeCableY
    end
    
    methods
        function obj = DorsiFlexionSpringPosition(position, patientHeight, anthroDimensionMap, ...
                hipAngleZ, kneeAngleZ, ankleAngleZ, footAngleZ)
        %% Setting up the variables to be used
        r = obj.radiusOfPulley; %radius of the pulley wheel
        global leftShankLength thighLength;
        lThigh = anthroDimensionMap(thighLength);
        lShank = anthroDimensionMap(leftShankLength);
        hipAngleZRads = deg2rad(hipAngleZ);
        kneeAngleZRads = deg2rad(kneeAngleZ);
        footAngleZRads = deg2rad(footAngleZ);
                
        obj.pullyDistanceFromTheCenterLine = (0.06/1.78)*patientHeight;
        
        %% Determining the coordinates of 4 points
        P1X =  position.ThighComXPoint + (0.05+r)*cos(hipAngleZRads);
        P1Y = position.ThighComYPoint + (0.05+r)*sin(hipAngleZRads);

        P2X = obj.thighPulleyPercentDownThigh*lThigh*sin(hipAngleZRads) + (0.05+r)*cos(hipAngleZRads);
        P2Y = -obj.thighPulleyPercentDownThigh*lThigh*cos(hipAngleZRads) + (0.05+r)*sin(hipAngleZRads);

        if (kneeAngleZRads>hipAngleZRads)
            P3X = position.KneeJointX - obj.shankPullyPercentDownShank*lShank*sin(kneeAngleZRads-hipAngleZRads) + (0.05+r)*cos(kneeAngleZRads-hipAngleZRads);
            P3Y = position.KneeJointY - obj.shankPullyPercentDownShank*lShank*cos(kneeAngleZRads-hipAngleZRads) - (0.05+r)*sin(kneeAngleZRads-hipAngleZRads);
        elseif (kneeAngleZRads<hipAngleZRads)
            P3X = position.KneeJointX + obj.shankPullyPercentDownShank*lShank*sin(hipAngleZRads-kneeAngleZRads) + (0.05+r)*cos(hipAngleZRads-kneeAngleZRads);
            P3Y = position.KneeJointY - obj.shankPullyPercentDownShank*lShank*cos(kneeAngleZRads-hipAngleZRads) + (0.05+r)*sin(kneeAngleZRads-hipAngleZRads);
        end
        
        %P3X = position.ShankComXPoint;
        %P3Y = position.ShankComYPoint;
        
        
        %% Foot Pulley Position
        footPulleyXProj = position.ToeX;
        footPulleyYProj = position.ToeY + obj.distAboveToe;
        
        [P4X, P4Y] = obj.RotatePointsAroundPoint(footPulleyXProj, footPulleyYProj, ...
                footAngleZRads, position.ToeX, position.ToeY);
        
        %% Attachment of Cable
        obj.distanceFromAnkle2ToeCableX = P4X - position.AnkleJointX;
        obj.distanceFromAnkle2ToeCableY =  position.AnkleJointY -  P4Y;
        
        % Angle that the force is applied to the toe at
        AppliedForceAngleFromXAxis = 120;
        obj.AppliedToeCableForceAngle = AppliedForceAngleFromXAxis+footAngleZ;

        %% Determining overall length of the system
        obj.Length = sqrt(((P2X-P1X)^2)+((P2Y-P1Y)^2)) + sqrt(((P3X-P2X)^2)+((P3Y-P2Y)^2))+ ...
            + sqrt(((P4X-P3X)^2)+((P4Y-P3Y)^2));

        %% Create link vectors
        obj.Link1X = [P1X P2X];
        obj.Link1Y = [P1Y P2Y];
        obj.Link2X = [P2X P3X];
        obj.Link2Y = [P2Y P3Y];
        obj.Link3X = [P3X P4X];
        obj.Link3Y = [P3Y P4Y];
        
        %% Tests
        %obj.CheckLengthConsistent('Foot Attachment: ', [P3X P4X], [P3Y P4Y]);
        end
    end
    
    methods 
        function [xRotated, yRotated] = RotatePointsAroundPoint(~, initialX, initialY, angleInRads_CCW, ...
                pointToRotateAroundX, pointToRotateAroundY)
            % Rotate X co-ordinate
            xRotated = pointToRotateAroundX + [(initialX-pointToRotateAroundX)*cos(angleInRads_CCW)- (initialY-pointToRotateAroundY)*sin(angleInRads_CCW)];
            % Rotate Y co-ordinate
            yRotated = pointToRotateAroundY + [(initialX-pointToRotateAroundX)*sin(angleInRads_CCW)+ (initialY-pointToRotateAroundY)*cos(angleInRads_CCW)];
        end
        
        function CheckLengthConsistent(~, variableName, LineX, LineY)
            length = sum(sqrt(diff(LineX).^2+diff(LineY).^2));
            disp([variableName, num2str(length)])
        end
    end
end