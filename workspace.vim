nnoremap <localleader>rv :lua MyRun({"FloatermNew ./nrun.py -r vim -a simple", "FloatermShow", "startinsert"})<cr>
nnoremap <localleader>rf :lua MyRun({"FloatermNew ./nrun.py -r fish -a simple", "FloatermShow", "startinsert"})<cr>
nnoremap <localleader>rn :lua MyRun({"FloatermNew ./nrun.py -r nushell binary ", "FloatermShow", "startinsert"})<cr>
