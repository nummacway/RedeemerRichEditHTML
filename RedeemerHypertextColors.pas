unit RedeemerHypertextColors;

interface

uses
  Graphics, SysUtils;

type
  TColorName = record
    Color: TColor;
    Name: string;
  end;

function HTMLToColor(HTML: string; out Color: TColor; const ColorNames: array of TColorName): Boolean;

implementation

uses
  RedeemerSVGHelpers, shlwapi, StrUtils;

function HTMLToColor(HTML: string; out Color: TColor; const ColorNames: array of TColorName): Boolean;
procedure FindColor(const Pattern: string; const Low, High: Integer; var Result: TColor);
var
  n: Integer;
begin
  // Fail
  if Low > High then
  Exit;

  n := (Low+High) div 2;

  if ColorNames[n].Name > Pattern then
  FindColor(Pattern, Low, n-1, Result)
  else
  if ColorNames[n].Name < Pattern then
  FindColor(Pattern, n+1, High, Result)
  else
  Result := ColorNames[n].Color;
end;
const
  HexKey = '0123456789abcdef';
var
  Name, Content: string;
  Splitter: TCoordinates;
  c1, c2, c3: Extended;
begin
  Result := False;
  HTML := lowercase(HTML);
  if StartsStr('#', HTML) then
  case Length(HTML) of
    4..5: begin // #abc
         if (Pos(HTML[2], HexKey) > 0) and
            (Pos(HTML[3], HexKey) > 0) and
            (Pos(HTML[4], HexKey) > 0) then
         begin
           Color := (Pos(HTML[2], HexKey) - 1) * 17 +
                    (Pos(HTML[3], HexKey) - 1) * 4352 + // 17 * 256
                    (Pos(HTML[4], HexKey) - 1) * 1114112;  // 17 * 65536
           Result := True;
         end;
       end;
    7, 9: begin // #abcdef
         if (Pos(HTML[2], HexKey) > 0) and
            (Pos(HTML[3], HexKey) > 0) and
            (Pos(HTML[4], HexKey) > 0) and
            (Pos(HTML[5], HexKey) > 0) and
            (Pos(HTML[6], HexKey) > 0) and
            (Pos(HTML[7], HexKey) > 0) then
         begin
           Color := (Pos(HTML[2], HexKey) - 1) * 16 +
                    (Pos(HTML[3], HexKey) - 1) * 1 +
                    (Pos(HTML[4], HexKey) - 1) * 4096 +
                    (Pos(HTML[5], HexKey) - 1) * 256 +
                    (Pos(HTML[6], HexKey) - 1) * 1048576 +
                    (Pos(HTML[7], HexKey) - 1) * 65536;
           Result := True;
         end;
       end;
  end
  else if TStyleSplitter.GetBracket(HTML, Name, Content) then
  begin
    Splitter := TCoordinates.Create(Content);
    try
      if (Name = 'rgba') or (Name = 'rgb') then
      begin
        if Splitter.GetNextCoordinate(255,c1) then
        if Splitter.GetNextCoordinate(255,c2) then
        if Splitter.GetNextCoordinate(255,c3) then
        begin
          Color := 65536 * (Round(c3) mod 256) + 256 * (Round(c2) mod 256) + (Round(c1) mod 256);
          Result := True;
        end;
      end
      else
      if (Name = 'hsla') or (Name = 'hsl') then // Windows erwartet einen maximalen Wert von [0..240] skalieren (beim zweiten und dritten Wert ist eigentlich kein absoluter Wert möglich)
      if Splitter.GetNextCoordinate(360,c1) then
      if Splitter.GetNextCoordinate(240,c2) then
      if Splitter.GetNextCoordinate(240,c3) then
      begin
      Color := shlwapi.ColorHLSToRGB(Round(c1/3*2),Round(Abs(c3)),Round(Abs(c2)));
      Result := True;
      end;
    finally
      Splitter.Free;
    end;
  end
  else
  begin
    Color := clNone;
    FindColor(HTML, Low(ColorNames), High(ColorNames), Color);
    if not (Color = clNone) then
    Result := True;
  end;
end;

end.
