! a table written by the program: statistics of the last 60 iterations
r = stats(cd(61:))
write(md, '(A)') '## Statistics', '', 'The last 60 iterations, after the restart.', '', &
                 '| quantity | mean | standard deviation | min | max |', '| --- | --: | --: | --: | --: |'
write(md, '(A,4(" | ",F8.5)," |")') '| drag coefficient', r%y%mean, r%y%stddev, r%y%min, r%y%max
r = stats(log10(rho(61:)))
write(md, '(A,4(" | ",F8.3)," |")') '| log10 continuity residual', r%y%mean, r%y%stddev, r%y%min, r%y%max
write(md, '(A)') ''
