export MY_N=450

MY_KIND=dense MY_O=1 sbatch -J lr1 seq.job
MY_KIND=dense MY_O=2 sbatch -J lr2 seq.job
MY_KIND=lowrank MY_O=1 sbatch -J de1 seq.job
MY_KIND=lowrank MY_O=2 sbatch -J de2 seq.job
