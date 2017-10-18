function y = confusionMatrix(pred, data)
    y = zeros(7);
    for i=1:numel(data)
        y(data(i), pred(i)) = y(data(i), pred(i)) + 1;
    end
    printmat(y, 'Confusion Matrix', ...
        'BALL COTT PILL SALT SODA SPIC SPOU',...
        'BALL COTT PILL SALT SODA SPIC SPOU');
    y
end
        
