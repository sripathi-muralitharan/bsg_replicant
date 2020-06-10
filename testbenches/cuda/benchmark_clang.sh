kernel=vec_add

benchmark_kernel()
{
  stats_dir=$1
  rm -r $stats_dir
  make clean
  if [ "$#" -eq "1" ] ; then
    eval "make test_\${kernel}.vanilla_stats.csv 2>&1 | tee run.log"
  elif [ "$#" -eq "2" ] ; then
    eval "make test_\${kernel}.vanilla_stats.csv CLANG=$2 2>&1 | tee run.log"
  else
    eval "make test_\${kernel}.vanilla_stats.csv CLANG=$2 LLVM_DIR=$3 2>&1 | tee run.log"
  fi
  eval "PYTHONPATH=../../../bsg_manycore/software/py python -m vanilla_parser --only stats_parser --stats=/mnt/users/ssd1/no_backup/bandhav/bsg_bladerunner/bsg_replicant/testbenches/cuda/test_vec_add.vanilla_stats.csv"
  mv stats $stats_dir
  eval "mv test_\${kernel}.log \${stats_dir}/"
  eval "mv run.log \${stats_dir}/"
  eval "make -C /mnt/users/ssd1/no_backup/bandhav/bsg_bladerunner/bsg_manycore/software/spmd/bsg_cuda_lite_runtime/\${kernel} main.dis > \${stats_dir}/dis"
  eval "cp /mnt/users/ssd1/no_backup/bandhav/bsg_bladerunner/bsg_manycore/software/spmd/bsg_cuda_lite_runtime/\${kernel}/main.riscv \${stats_dir}/main.riscv"
  make clean
}

eval "benchmark_kernel \${kernel}_stats_gcc"
eval "benchmark_kernel \${kernel}_stats_clang_upstream 1"
eval "benchmark_kernel \${kernel}_stats_clang_custom 1 /mnt/users/ssd1/no_backup/bandhav/bsg-llvm-project/build"
