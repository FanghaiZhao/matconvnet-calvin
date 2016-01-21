function convertNetwork(obj)
% convertNetwork(obj)
%
% Converts a network from test to train, inserting lossed, dropout and
% adopting the classification layer.
%
% Copyright by Holger Caesar, 2015

% Add dropout layers after relu6 and relu7
dropout6Layer = dagnn.DropOut();
dropout7Layer = dagnn.DropOut();
obj.net.insertLayer('relu6', 'fc7', 'dropout6', dropout6Layer);
obj.net.insertLayer('relu7', 'fc8', 'dropout7', dropout7Layer);

% Replace softmax with correct loss for training (default: softmax)
switch obj.nnOpts.lossFnObjective
    case 'softmaxlog'
        softmaxlossBlock = dagnn.LossWeighted('loss', 'softmaxlog');
        obj.net.replaceLayer('prob', 'softmaxloss', softmaxlossBlock, 'label');
        obj.net.renameVar(obj.net.layers(obj.net.getLayerIndex('softmaxloss')).outputs, 'objective');
    case 'hinge'
        hingeLossBlock = dagnn.Loss('loss', 'hinge');
        obj.net.replaceLayer('prob', 'hingeloss', hingeLossBlock, 'label');
        obj.net.renameVar(obj.net.layers(obj.net.getLayerIndex('hingeloss')).outputs, 'objective');
    otherwise
        error('Wrong loss specified');
end

% Adapt number of classes in softmaxloss layer from 1000 to numClasses
fc8Idx = obj.net.getLayerIndex('fc8');
obj.net.layers(fc8Idx).block.size(4) = obj.imdb.numClasses;
newParams = obj.net.layers(fc8Idx).block.initParams();
obj.net.params(obj.net.layers(fc8Idx).paramIndexes(1)).value = newParams{1} / std(newParams{1}(:)) * 0.01; % Girshick initialization
obj.net.params(obj.net.layers(fc8Idx).paramIndexes(2)).value = newParams{2}';

% Rename input
obj.net.renameVar('x0', 'input');