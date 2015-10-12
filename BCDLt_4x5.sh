#!/bin/sh
#SBATCH --job-name="BCDLt_4x5"
#SBATCH --output="RESULTS/%j.BCDLt_4x5.%N.out"
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --export=ALL
#SBATCH -t 47:59:59


FormulaName="BCDLt"
AtomsNum=8
CrossbarR=4
CrossbarC=5
FILE="${FormulaName}_${CrossbarR}x${CrossbarC}.smt2"

LiteralsNum=`expr $AtomsNum \* 2`

LowerHalfLow=0
LowerHalfHigh=`expr $AtomsNum - 1`
UpperHalfLow=`expr $AtomsNum`
UpperHalfHigh=`expr $LiteralsNum - 1`

#THE ATOMS AND THEIR NEGATIONS
AtomsAndNegations=""

twoPow=1
for i in `seq 0 $(expr $AtomsNum - 1)`;
do
	AtomsAndNegations="$AtomsAndNegations
	(define-const a$i  (AndClause) (_ bv$twoPow $LiteralsNum) )"
	
	twoPow=`expr $twoPow + $twoPow`
done

for i in `seq 0 $(expr $AtomsNum - 1)`;
do
	AtomsAndNegations="$AtomsAndNegations
	(define-const na$i (AndClause) (_ bv$twoPow $LiteralsNum) )"

	twoPow=`expr $twoPow + $twoPow`
done

#declaration of the memristors

memristorNum=`expr $CrossbarR \* $CrossbarC`
memristorsDecs=""

for i in `seq 0 $(expr $memristorNum - 1)`
do
	memristorDecs="$memristorDecs
	(declare-const m$i  (AndClause) )"
done

memristorLegVals=""
#Legal values for the memristors
for i in `seq 0 $(expr $memristorNum - 1)`
do
	memristorLegVals="$memristorLegVals
	(assert (or
					(= m$i TRUE)
					(= m$i FALSE)"
	
	for m in `seq 0 $(expr $AtomsNum - 1)`
	do
		memristorLegVals="$memristorLegVals
					(= m$i a$m )
					(= m$i na$m)"
	
	done
	memristorLegVals="$memristorLegVals
	))
	"
done

maxR=`expr $CrossbarR - 1`
SneakPaths=$(cat "SNEAKPATHS/${CrossbarR}x${CrossbarC}_r$maxR")
SneakPathsNum=$(wc -l < "SNEAKPATHS/${CrossbarR}x${CrossbarC}_r$maxR")
#wc -l <<<"$SneakPaths"
#SneakPathsNum=`wc -l <<< "$SneakPaths"`

Formula=$(cat "FORMULAS/$FormulaName")
FormulaNum=`wc -l < "FORMULAS/$FormulaName"`


#Map Paths to AndClauses

mapPath2Formula=""

for p in `seq 0 $(expr $SneakPathsNum - 1)`
do

	mapPath2Formula="$mapPath2Formula
	(assert (or"

	for f in `seq 0 $(expr $FormulaNum - 1)`
	do
		mapPath2Formula="$mapPath2Formula
		(= P$p F$f)"
	done
	
	mapPath2Formula="$mapPath2Formula
		(IsFALSE P$p)
	))
	"

done

#Map AndClauses to Paths

mapFormula2Path=""

for f in `seq 0 $(expr $FormulaNum - 1)`
do

	mapFormula2Path="$mapFormula2Path
	(assert (or"

	for p in `seq 0 $(expr $SneakPathsNum - 1)`
	do
		mapFormula2Path="$mapFormula2Path
		(= F$f P$p)"
	done
	
	mapFormula2Path="$mapFormula2Path
	))
	"

done

memristorsList=""
for m in `seq 0 $(expr $memristorNum - 1)`
do
	memristorsList="${memristorsList}m$m "
done


/bin/cat <<EOM >$FILE

; #THE LITERALS

(define-sort AndClause () (_ BitVec $LiteralsNum) )

(define-const FALSE (AndClause) (bvnot (_ bv0 $LiteralsNum)) )	; #All ones!
(define-const TRUE (AndClause) (_ bv0 $LiteralsNum) )

(define-fun IsFALSE ((clause AndClause)) Bool
	(not
		(=
			(_ bv0 $AtomsNum) ; #All zeros
			
			(bvand
				((_ extract $UpperHalfHigh $UpperHalfLow) clause)
				((_ extract $LowerHalfHigh  $LowerHalfLow ) clause)
			)
			
		)
	)
)

; #THE ATOMS AND THEIR NEGATIONS
$AtomsAndNegations

; #THE MEMRISTORS
$memristorDecs

; #LEGAL VALUES FOR THE MEMRISTORS ***SUSPICIOUS***
$memristorLegVals

; #THE SNEAK PATHS

$SneakPaths

; #Formula's And Clauses

$Formula

; #The Mapping

$mapPath2Formula

; #The mapping should be onto

$mapFormula2Path

; #Output
(check-sat)

(get-value (
	$memristorsList
))
EOM

date
./z3 $FILE
date
