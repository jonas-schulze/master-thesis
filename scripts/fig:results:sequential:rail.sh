export MY_N=450

MY_KIND=dense MY_O=1 sbatch -N1 -c1 -J lr1 seq.job
MY_KIND=dense MY_O=2 sbatch -N1 -c1 -J lr2 seq.job
MY_KIND=lowrank MY_O=1 sbatch -N1 -c1 -J de1 seq.job
MY_KIND=lowrank MY_O=2 sbatch -N1 -c1 -J de2 seq.job
