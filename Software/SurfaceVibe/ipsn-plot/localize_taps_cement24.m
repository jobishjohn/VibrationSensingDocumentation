% clear all
% close all
% clc

init();
s = Surface([40 40]);
s.addSensor(0,0);
s.addSensor(1,0);
s.addSensor(0,1);
s.addSensor(1,1);
tdoaCalc = FirstPeakTdoaCalculator();
% first peak setting MPH = max(sig)/4;
% prepare renderer
renderer = SurfaceRenderer(s);
renderer.plot();
estErr = [];

GT{1} = [5,5];
GT{2} = [15,5];
GT{3} = [25,5];
GT{4} = [35,5];
GT{5} = [5,15];
GT{6} = [15,15];
GT{7} = [25,15];
GT{8} = [35,15];
GT{9} = [5,25];
GT{10} = [15,25];
GT{11} = [25,25];
GT{12} = [35,25];
GT{13} = [5,35];
GT{14} = [15,35];
GT{15} = [25,35];
GT{16} = [35,35];

evaIdx = 1;
for velocity = [14000 6000] %[17000 6000]
    localizer = PairLocalizer(s, [1,1,1,1,1,1].*velocity);

    for bandIdx = 14%[14 20] %30-->20
        renderer = SurfaceRenderer(s);
        renderer.plot();
        estErr = [];
        load('data/drive/dataset/cement24-tap.mat');
        for tapIdx = 0:15
            tapIdx
            bFilter = WaveletFilter();
            bFilter.noiseMaxScale=bandIdx;
            tdoas = [];
            points = [];
            for idx = 1:length(events{tapIdx+1})
               e = events{tapIdx+1}(idx);
               if velocity ~= 6000 || bandIdx ~= 20 %30-->20
                    e.filter(bFilter);
               end
%                e.plot();
               oneTdoa = e.getTdoa(tdoaCalc);
               onePoint = localizer.resolve(oneTdoa);
               
               tdoas = [tdoas; oneTdoa];
               % check point location, if it is off too much, check the
               % second one, if both off, discard
               if sqrt(sum((onePoint - [20,20]).^2)) > 30
                   continue;
               end
               if onePoint(1) == 0 && onePoint(2) == 0
                   continue;
               elseif onePoint(1) <= 0.05 && abs(onePoint(2)) >= 39.5
                   continue;
               elseif onePoint(2) <= 0.05 && abs(onePoint(1)) >= 39.5
                   continue;
               end
               points = [points; onePoint];
            end
            tdoaAll{tapIdx+1} = tdoas;
            pointsAll{tapIdx+1} = points;
            if size(points,1) >= 2
                renderer.addPoints(points);hold on;
                ptCenter = mean(points);
                if sum(isnan(ptCenter)) == 0
                    plot([ptCenter(1),GT{tapIdx+1}(1)],[ptCenter(2),GT{tapIdx+1}(2)],'k');
                    estErr = [estErr; sqrt(sum((ptCenter-GT{tapIdx+1}).^2))];
                end
                title([num2str(velocity) '-' num2str(bandIdx)]);
            end
            hold off;
        end
        drawnow;
        evaluation{evaIdx} = struct('tdoa', tdoaAll, ...
                    'points', pointsAll, ...
                    'error', estErr, ...
                    'velocity', velocity, ...
                    'band', bandIdx);
        evaIdx = evaIdx + 1;
    end
end


mean(estErr)
std(estErr)

save('cement24-undamped-tap-results.mat','evaluation');

% testTdoas = [];
% for tapIdx = 1:16
%     temp = mean(tdoaAll{tapIdx});
%     if ~isnan(
%     temp = temp-temp(1);
%     testTdoas = [testTdoas; temp];
% end


