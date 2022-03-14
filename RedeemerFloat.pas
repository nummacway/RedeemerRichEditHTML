unit RedeemerFloat;

interface

function ReadFloat(s: String): Extended;

implementation

uses
  SysUtils, StrUtils, Math;

function ReadFloat(s: String): Extended;
var
  IntPart: Integer;
  FracPart: Integer;
  Factor: Integer;
  Exponent: Extended;
begin
  IntPart := Pos('e', s);
  if IntPart > 0 then
  begin
    Exponent := IntPower(10,StrToInt(RightStr(s, Length(s) - IntPart)));
    s := Copy(s, 1, IntPart - 1);
  end
  else
  Exponent := 1;

  if Pos('.', s) > 0 then
  begin
    IntPart := StrToInt64Def(Copy(s, 1, Pos('.', s) - 1), 0);
    FracPart := StrToInt64('1' + Copy(s, Pos('.', s) + 1, 1337));
    // This looks complicated but to me it seems to be the method with the
    // least loss of accuracy
    // FracPart represents the post-comma digits with a leading 1.
    // Factor is set to 2 to make sure it's bigger than FracPart until the
    // factors match. After that, it's turned into a power of 10 (like it was
    // 1 from the start).
    Factor := 2;
    while Factor < FracPart do
    Factor := Factor * 10;
    Factor := Factor div 2;
    if s[1] = '-' then
    Result := Exponent * (IntPart - (FracPart / Factor) + 1)
    else
    Result := Exponent * (IntPart + (FracPart / Factor) - 1)
  end
  else
  Result := Exponent * StrToInt64Def(s, -1);
end;

end.
