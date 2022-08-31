program Mine;

uses Termio;

{ Types used for this game }
type
   Cell = (Empty, Bomb);
   Field = record
              Cells: array of Cell;
              Open: array of Boolean;
              Rows: Integer;
              Cols: Integer;
              CursorRow: Integer;
              CursorCol: Integer;
           end;

{ Converts a Row, and Col position to an index in the Field.Cells array for the given field }
function FieldIndexFromPosition(Field : Field; Row, Col : Integer ): Integer;
begin
   FieldIndexFromPosition := Row*Field.Cols + Col;
end;

{ Gets the Cell at a given Row, and Cell position }
function FieldGet(Field: Field; Row, Col: Integer): Cell;
begin
   FieldGet := Field.Cells[FieldIndexFromPosition(Field, Row, Col)];
end;

{ Check if the Cell in the given Row, and Col position is open }
function FieldIsOpen(Field: Field; Row, Col: Integer): Boolean;
begin
   FieldIsOpen := Field.Open[FieldIndexFromPosition(Field, Row, Col)];
end;

{ Open the Cell at the cursor position, and return the cell  }
function FieldOpenAtCursor(var Field: Field): Cell;
var
   Index : Integer;
begin
   Index := FieldIndexFromPosition(Field, Field.CursorRow, Field.CursorCol);
   Field.Open[Index] := True;
   FieldOpenAtCursor := Field.Cells[Index];
end;

{ Check if given Row, and Col position is within bounds, and gives the cell velue through the given cell referance. Also it returns a boolean saying if it was within bounds or not }
function FieldCheckedGet(Field: Field; Row, Col: Integer; var Cell: Cell): Boolean;
begin
   FieldCheckedGet := (0 <= Row) and (Row < Field.Rows) and (0 <= Col) and (Col < Field.Cols);
   if FieldCheckedGet then Cell := FieldGet(Field, Row, Col);
end;

{ Set the Cell value at a given Row, and Col position in a given field }
procedure FieldSet(var Field: Field; Row, Col: Integer; Cell: Cell);
begin
   Field.Cells[FieldIndexFromPosition(Field, Row, Col)] := Cell;
end;

{ Resize the cells array in field to match the given dimensions. It also closes all the cells }
procedure FieldResize(var Field: Field; Rows, Cols: Integer);
var
   Index : Integer;
begin
   { Resizes Cells }
   SetLength(Field.Cells, Rows*Cols);
   { Resizes Open }
   SetLength(Field.Open, Rows*Cols);
   { Sets the new Width/Height (Rows/Cols) }
   Field.Rows := Rows;
   Field.Cols := Cols;
   { Sets all cells as not open }
   for Index := 0 to Rows*Cols do Field.Open[Index] := False;
   { Resets cursor position }
   Field.CursorRow := 0;
   Field.CursorCol := 0;
end;

{ Check if the gived Row, and Col position is the same as the cursor position }
function FieldAtCursor(Field: Field; Row, Col: Integer): Boolean;
begin
   FieldAtCursor := (Field.CursorRow = Row) and (Field.CursorCol = Col);
end;

{ Gives random Row, and Col positions through the given references. Also it returns the Cell value of that position }
function FieldRandomCell(Field: Field; var Row, Col: Integer): Cell;
begin
   Row := Random(Field.Rows);
   Col := Random(Field.Cols);
   FieldRandomCell := FieldGet(Field, Row, Col);
end;

{ Check if the given Row, Col position is within a 3x3 square around the cursor. }
function FieldAroundCursor(Field : Field; Row, Col: Integer ): Boolean;
var
   DRow, DCol : Integer;
begin
   for DRow := -1 to 1 do
      for DCol := -1 to 1 do
         if (Field.CursorRow + DRow = Row) and (Field.CursorCol + DCol = Col) then
            Exit(True);
   FieldAroundCursor := False;
end;

{ Generate/Randomize the Field values }
procedure FieldRandomize(var Field: Field; BombsPercentage: Integer);
var
   Index, BombsCount: Integer;
   Row, Col: Integer;
begin
   { Sets all cells as empty }
   for Index := 0 to Field.Rows*Field.Cols do Field.Cells[Index] := Empty;
   { TODO: Find a better way to prevent an infinite loop other than reducing the max percentage }
   if BombsPercentage > 90 then BombsPercentage := 90;
   BombsCount := (Field.Rows*Field.Cols*BombsPercentage + 99) div 100;
   { Generate bombs }
   for Index := 1 to BombsCount do
   begin
      { Avoid bomb position being over another bomb, the cursor, or within a 3x3 suare of the cursor }
      while (FieldRandomCell(Field, Row, Col) = Bomb) or FieldAtCursor(Field, Row, Col) or FieldAroundCursor(Field, Row, Col) do;
      FieldSet(Field, Row, Col, Bomb);
   end;
end;

{ Open all the cells that are bombs }
procedure FieldOpenBombs(var Field : Field );
var
   Index :  Integer;
begin
   for Index := 0 to Field.Rows*Field.Cols do
      if Field.Cells[Index] = Bomb then
         Field.Open[Index] := True;
end;

{ Count the neighbouring bomb cells }
function FieldCountNbors(Field: Field; Row, Col: Integer): Integer;
var
   DRow, DCol: Integer;
   C: Cell;
begin
   { amount of neighboring bombs }
   FieldCountNbors := 0;
   { Loop over delta row -1 to 1 }
   for DRow := -1 to 1 do
      { Loop over delta col -1 to 1 }
      for DCol := -1 to 1 do
         { dount count the middle cell }
         if (DRow <> 0) or (DCol <> 0) then
            { get cell value }
            if FieldCheckedGet(Field, Row + DRow, Col + DCol, C) then
               { if it is a bomb, increase amount of neighboting bombs }
               if C = Bomb then
                  inc(FieldCountNbors);
end;

{ Print out the field }
procedure FieldWrite(Field: Field);
var
   Row, Col, Nbors: Integer;
begin
   { Loop rows }
   for Row := 0 to Field.Rows-1 do
   begin
      { Loop cols }
      for Col := 0 to Field.Cols-1 do
      begin
         { Wrap cursor pos with [  ] }
         if FieldAtCursor(Field, Row, Col) then Write('[') else Write(' ');
         { if field ope, print '@' for bomb, ' ' for empty, '.' for closed' }
         if FieldIsOpen(Field, Row, Col) then
            case FieldGet(Field, Row, Col) of
              Bomb: Write('@');
              Empty: begin
                        { if the empty cell has neighboring bombs, show the amount of neighboring bombs instead }
                        Nbors := FieldCountNbors(Field, Row, Col);
                        if Nbors > 0 then Write(Nbors) else Write(' ');
                     end;
            end else Write('.');
         { Wrap cursor pos with [  ] }
         if FieldAtCursor(Field, Row, Col) then Write(']') else Write(' ');
      end;
      { Newline }
      WriteLn
   end;
end;

{ Reset position of the terminal cursor to the start }
procedure CursorBack(Field : Field );
begin
   Write(Chr(27), '[', Field.Rows,   'A');
   Write(Chr(27), '[', Field.Cols*3, 'D');
end;

const
   STDIN_FILENO = 0;
var
   MainField         : Field;
   Quit              : Boolean = False;
   First             : Boolean = True;
   SavedTAttr, TAttr : Termios;
   Cmd               : Char;
begin
   { Random rng seed }
   Randomize;
   { Set the field size }
   FieldResize(MainField, 10, 10);

   { Check if stdin is terminal }
   if IsATTY(STDIN_FILENO) = 0 then
   begin
      WriteLn('ERROR: this is not a terminal!');
      Exit;
   end;
   { get terminal attributes }
   TCGetAttr(STDIN_FILENO, TAttr);
   { make backup of terminal attributes }
   TCGetAttr(STDIN_FILENO, SavedTAttr);
   { terminal magic to hide inputed text }
   TAttr.c_lflag := TAttr.c_lflag and (not (ICANON or ECHO));
   TAttr.c_cc[VMIN] := 1;
   TAttr.c_cc[VTIME] := 0;
   TCSetAttr(STDIN_FILENO, TCSAFLUSH, TAttr);

   { print out the field }
   FieldWrite(MainField);

   { game loop }
   while not Quit do
   begin
      { take user input, e.g. 'w', 'a', 's', 'd', ' ' }
      Read(Cmd);
      { Handle input }
      case Cmd of
        { move cursor }
        'w': if MainField.CursorRow > 0                then dec(MainField.CursorRow);
        's': if MainField.CursorRow < MainField.Rows-1 then inc(MainField.CursorRow);
        'a': if MainField.CursorCol > 0                then dec(MainField.CursorCol);
        'd': if MainField.CursorCol < MainField.Cols-1 then inc(MainField.CursorCol);
        { show cell }
        ' ': begin
           { if this is the first cell, generate/randomize the field }
           if First then
           begin
              FieldRandomize(MainField, 20);
              First := False;
           end;
           { if the opened cell is a bomb, game over }
           if FieldOpenAtCursor(MainField) = Bomb    then
           begin
              { open all the fields with bombs in them }
              FieldOpenBombs(MainField);

              { reset terminal cursor position, and print field }
              CursorBack(MainField);
              FieldWrite(MainField);

              { game over message }
              WriteLn('Game Over!');

              Quit := True;
              break;
           end;
        end;
      end;
      { reset terminal cursor position, and print field }
      CursorBack(MainField);
      FieldWrite(MainField);
   end;

   { Reset terminal attributes back to normal }
   TCSetAttr(STDIN_FILENO, TCSANOW, SavedTAttr);
end.

Minesweeper for the terminal. Made using Free Pascal.
