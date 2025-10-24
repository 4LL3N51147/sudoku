package main

import (
	"fmt"
	"math/rand"
	"reflect"
	"sort"
)

func main() {
	b := NewBoard()
	b.PrintCandidates()
}

type Cell struct {
	Value      int
	Candidates map[int]struct{}
}

func NewCell() *Cell {
	return &Cell{
		Candidates: map[int]struct{}{
			1: {}, 2: {}, 3: {},
			4: {}, 5: {}, 6: {},
			7: {}, 8: {}, 9: {},
		},
	}
}

func (c *Cell) Populate() {
	keys := reflect.ValueOf(c.Candidates).MapKeys()
	if len(keys) == 0 {
		return
	}
	randomIndex := rand.Intn(len(keys))
	c.Value = keys[randomIndex].Interface().(int)
}

type Block struct {
	RowCells map[int][]*Cell
	ColCells map[int][]*Cell
}

func NewBlock() *Block {
	rowCells := map[int][]*Cell{
		0: {NewCell(), NewCell(), NewCell()},
		1: {NewCell(), NewCell(), NewCell()},
		2: {NewCell(), NewCell(), NewCell()},
	}
	colCells := map[int][]*Cell{
		0: make([]*Cell, 3),
		1: make([]*Cell, 3),
		2: make([]*Cell, 3),
	}
	for i := range rowCells {
		for j := range rowCells[i] {
			colCells[j][i] = rowCells[i][j]
		}
	}
	return &Block{
		RowCells: rowCells,
		ColCells: colCells,
	}
}

func (b *Block) Populate() {
	for _, row := range b.RowCells {
		for _, cell := range row {
			cell.Populate()
			b.UpdateCandidates(cell.Value)
		}
	}
}

func (b *Block) UpdateCandidates(n int) {
	for _, cells := range b.RowCells {
		for _, cell := range cells {
			delete(cell.Candidates, n)
		}
	}
}

func (b *Block) UpdateColCandidate(c int, nums []int) {
	for _, cell := range b.ColCells[c] {
		for _, n := range nums {
			delete(cell.Candidates, n)
		}
	}
}

func (b *Block) UpdateRowCandidate(r int, nums []int) {
	for _, cell := range b.RowCells[r] {
		for _, n := range nums {
			delete(cell.Candidates, n)
		}
	}
}

func (b *Block) Print() {
	for _, row := range b.RowCells {
		for _, cell := range row {
			fmt.Printf("%d ", cell.Value)
		}
		fmt.Println()
	}
}

func (b *Block) Values() [][]int {
	values := make([][]int, 3)
	for i, row := range b.RowCells {
		values[i] = make([]int, 3)
		for j, cell := range row {
			values[i][j] = cell.Value
		}
	}
	return values
}

func (b *Block) PrintCandidates() {
	for _, row := range b.RowCells {
		for i, cell := range row {
			candidates := make([]int, 0)
			for k := range cell.Candidates {
				candidates = append(candidates, k)
			}
			sort.Ints(candidates)
			fmt.Print(candidates)
			if i != len(b.RowCells)-1 {
				fmt.Printf(" | ")
			}
		}
		fmt.Println()
	}
}

type Board struct {
	RowBlocks map[int][]*Block
	ColBlocks map[int][]*Block
}

func NewBoard() *Board {
	rowBlocks := map[int][]*Block{
		0: {NewBlock(), NewBlock(), NewBlock()},
		1: {NewBlock(), NewBlock(), NewBlock()},
		2: {NewBlock(), NewBlock(), NewBlock()},
	}
	colBlocks := map[int][]*Block{
		0: make([]*Block, 3),
		1: make([]*Block, 3),
		2: make([]*Block, 3),
	}
	for i, row := range rowBlocks {
		for j, Block := range row {
			colBlocks[j][i] = Block
		}
	}
	return &Board{
		RowBlocks: rowBlocks,
		ColBlocks: colBlocks,
	}
}

func (b *Board) UpdateRowCandidate(rowNum int, n []int) {
	for _, block := range b.RowBlocks[rowNum/3] {
		block.UpdateRowCandidate(rowNum%3, n)
	}
}

func (b *Board) UpdateColCandidate(colNum int, n []int) {
	for _, block := range b.ColBlocks[colNum/3] {
		block.UpdateColCandidate(colNum%3, n)
	}
}

func (b *Board) UpdateByBlock(bi, bj int, block *Block) {
	values := block.Values()
	colValues := make([][]int, 3)
	for i, row := range values {
		b.UpdateRowCandidate(bi*3+i, row)
		for j, v := range row {
			if colValues[j] == nil {
				colValues[j] = make([]int, 3)
			}
			colValues[j][i] = v
		}
	}
	for i, col := range colValues {
		b.UpdateColCandidate(bj*3+i, col)
	}
}

func (b *Board) Populate() {
	for i, row := range b.RowBlocks {
		for j, block := range row {
			block.Populate()
			b.UpdateByBlock(i, j, block)
		}
	}
}

func (b *Board) Print() {
	for _, blockRow := range b.RowBlocks {
		for _, block := range blockRow {
			for _, row := range block.RowCells {
				for _, cell := range row {
					fmt.Printf("%d ", cell.Value)
				}
			}
		}
		fmt.Println()
	}
}

func (b *Board) PrintCandidates() {
	for _, bRow := range b.RowBlocks {
		for i := 0; i < 3; i++ {
			for _, block := range bRow {
				for j, cell := range block.RowCells[i] {
					candidates := make([]int, 0)
					for k := range cell.Candidates {
						candidates = append(candidates, k)
					}
					sort.Ints(candidates)
					fmt.Print(candidates)
					if j != 2 {
						fmt.Print(" | ")
					}
				}
			}
			fmt.Println()
		}
	}
}
