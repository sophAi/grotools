#!/bin/bash
if [ "$1" == "" ]; then
  echo -e "Please input the name of the pdb file(without .pdb) first"
  echo -e "ex:TTR"
  read -p ": " pdb_file
else
  pdb_file=$1
fi
echo -e "The input file is "$pdb_file".pdb"
until [ "$gromacs_sel" == 0 ]
do
  echo -e "============gromacs menu=============="
  echo -e "0 Quit"
  echo -e "1.Generate top and gro form pdb"
  echo -e "2.Edit box and solvent"
  echo -e "3.Pre-optimize top and gro file"
  echo -e "4.Position restrained MD"
  echo -e "5.Run the MD"
  echo -e "======================================"
  read -p ": " gromacs_sel
  case $gromacs_sel in
    1)
#    pdb2gmx -f $pdb_file.pdb -o $pdb_file.gro -p $1.top -ter
      pdb2gmx -f $pdb_file'.pdb' -o $pdb_file.gro -p $pdb_file'.top' -water tip4p -ignh -ter;;  #here use -water tip4p instead of spc

    2)
      editconf -f $pdb_file'.gro' -o $pdb_file'.gro' -d 0.5
      genbox -cp $pdb_file'.gro' -cs tip4p.gro -o $pdb_file'_b4em.gro' -p $pdb_file'.top'  #for water model spc, use -cs spc216.gro
      make_ndx -f $pdb_file'_b4em.gro';;
    3) 
      echo -e "Please prepare the file em.mdp"
      vi em.mdp
      grompp -f em -c $pdb_file'_b4em' -p $pdb_file -o $pdb_file'_em'
      mdrun -s $pdb_file'_em' -o $pdb_file'_em' -c $pdb_file'_b4pr' -v
      g_density -f $pdb_file'_em' -s $pdb_file'_em' -o $pdb_file'_em_density';;
      g_energy 
    4)
      echo -e "Please prepare the file pr.mdp"
      vi pr.mdp #-c read TTR_b4pr.gro ; -r read TTR_b4pr.gro ; -p read TTR.top ; -o output TTR_pr.tpr for mdrun
      grompp -f pr -c $pdb_file'_b4pr' -r $pdb_file'_b4pr' -p $pdb_file -o $pdb_file'_pr'
      echo -e "Please input the node number for mdrun"
      read -p ":" node
      case $node in
          1)
            mdrun -nice 4 -s $pdb_file'_pr' -o $pdb_file'_pr' -c $pdb_file'_b4md' & ;;
#   -s read TTR_pr.tpr ; -o TTR_pr.trr ; -c output TTR_b4md.gro ; -v be loud
          *)
            vi mpd_job
            mpiexec -machinefile mpd_job -n $node mdrun_mpi -s $pdb_file'_pr' -o $pdb_file'_pr' -c $pdb_file'_b4md' & ;;
      esac;;
    5)
      echo -e "Please prepare the file md.mdp" 
      vi md.mdp
      grompp -f md -c $pdb_file'_b4md' -p $pdb_file -o $pdb_file'_md'
      echo -e "Please input the node number for mdrun"
      read -p ":" node
      case $node in
          1)
            mdrun -nice 4 -s $pdb_file'_md' -o $pdb_file'_md' -c $pdb_file'_after_md' & ;;
          *)
            vi mpd_job
            mpiexec -machinefile mpd_job -n $node mdrun_mpi -s $pdb_file'_md' -o $pdb_file'_md' -c $pdb_file'_after_md' & ;;
      esac;;
  esac
done
time=`date`
echo -e " "
echo -e "Now it is "$time
echo -e "Have a nice day"
echo -e " "
exit 0

