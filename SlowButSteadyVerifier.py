import re

#The formula we are supposed to implement
def VerifyRes(bitVec, rows):
	return True


#Input the matrix

maxAtomIndex=0

R= input()
C= input()


class Literal:
	def __init__(self,atom, neg):
		self.atom= atom
		self.neg= neg
		
	def value(self, bitVec):
		if (self.neg):
			return not bitVec[self.atom]
		else:
			return bitVec[self.atom]

matrix= [ [Literal(0,False) for j in xrange(C)] for i in xrange(R)]

def PrintMatrix():
	for i in reversed(xrange(R)):
		for j in xrange(C):
			print(matrix[i][j].neg,matrix[i][j].atom),
		print()

for i in reversed(xrange(R)):
	curRow= re.findall(r'~?\d+' ,raw_input())
	for j in xrange(C):
		if curRow[j][0]=='~':
			matrix[i][j].neg=True
			matrix[i][j].atom= int(curRow[j][1:])
		else:
			matrix[i][j].neg=False
			matrix[i][j].atom= int(curRow[j])
			

		if matrix[i][j].atom> maxAtomIndex:
			maxAtomIndex= matrix[i][j].atom
			

def ResForBitVec(bitVec):
	rows= [False for i in xrange(R)]
	cols= [False for j in xrange(C)]
	
	rows[0]=True
	
	for t in xrange(R+C-1):
		for i in xrange(R):
			for j in xrange(C):
				if (cols[j] and matrix[i][j].value(bitVec)):
					rows[i]= True
		
		for j in xrange(C):
			for i in xrange(R):
				if (rows[i] and matrix[i][j].value(bitVec)):
					cols[j]= True

		return rows
		


#Now enumerate all bitvectors
bitVec= [False for i in xrange(maxAtomIndex+1)]

bitVecsNum=1
for i in xrange(maxAtomIndex+1):
	bitVecsNum= bitVecsNum *2
	
def FlipBit(index):
	if (index>maxAtomIndex):
		return
	if (bitVec[index]):
		bitVec[index]=False
		FlipBit(index+1)
	else:
		bitVec[index]=True
		
for i in xrange(bitVecsNum):
	VerifyRes(bitVec, ResForBitVec(bitVec))
	print bitVec
	FlipBit(0)
