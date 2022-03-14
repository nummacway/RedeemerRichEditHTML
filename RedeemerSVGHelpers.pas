unit RedeemerSVGHelpers;

interface

uses
  Generics.Collections;

type TStyle = class
  private
    var
      Properties: TDictionary<string, string>;
  public
    constructor Create(const Style: string);
    destructor Destroy; override;
    function GetProperty(const Attribute: string; out Value: string): Boolean;
end;

type TStyleSplitter = class // Klasse zum Splitten von einzelnen Bestandteilen von CSS-Werten (vor allem Schriftarten und Transformationen)
  public
    constructor Create(const S: string; const SplitAtSpace: Boolean);
    class function GetBracket(const S: string; out Name: string; out Value: string): Boolean;
    var
      Values: array of string;
end;

type TCoordinates = class
  private
    procedure ResetNumber();
    function IsNumber: Boolean;
    function IsDelimiter: Boolean;
  var
    S: string;
    L: Integer;
    CanDecimal: Boolean;
    CanMinus: Boolean;
    CanExponent: Boolean;
  public
    constructor Create(const S: string);
    class function MakeAbsolute(const PercentageMeasure: Extended; const Value: Extended): Extended;
    class function GetOnlyValue(const s: string; out Value: Extended): Boolean; overload;
    class function GetOnlyValue(const s: string; out Value: Extended; const PercentageMeasure: Extended): Boolean; overload;
    class function GetOnlyValueDef(const s: string; const Default: Extended): Extended; overload;
    class function GetOnlyValueDef(const s: string; const PercentageMeasure: Extended; const Default: Extended): Extended; overload;
    function GetNextCoordinate(out Value: Extended): Boolean; overload;
    function GetNextCoordinate(const PercentageMeasure: Extended; out Value: Extended): Boolean; overload;
    var
      Position: Integer;
end;

type TPath = class(TCoordinates)
  var
    SecondToLastType: Char;
    LastType: Char;
    LastWasRepeat: Boolean;
  public
    function GetNextNumber(out Value: Extended): Boolean;
    function GetNextFlag(out Value: Extended): Boolean; // liest höchstens ein Zeichen
    function GetNextType(): Char;
end;

implementation

uses
  StrUtils, RedeemerFloat, SysUtils;

{ TCoordinates }

constructor TCoordinates.Create(const S: string);
begin
  Self.S := S;
  Position := 1;
  L := Length(S);
end;

function TCoordinates.GetNextCoordinate(const PercentageMeasure: Extended; out Value: Extended): Boolean;
var
  temp: string;
  Factor: Extended;
begin
  Result := False;
  ResetNumber();
  if Position <= L then
  while (Position <= L) and not IsNumber do
  inc(Position);
  while not IsDelimiter do
  begin
    temp := temp + s[Position];
    inc(Position);
  end;

  if Temp = '' then
  Exit;

  Factor := 1;
  if EndsText('px', temp) then
  Delete(temp, Length(temp) - 1, 2) // Standardeinheit, ignorieren
  else
  if EndsText('pt', temp) then
  begin
    Delete(temp, Length(temp) - 1, 2);
    Factor := 4/3;
  end
  else
  if EndsText('%', temp) then
  if PercentageMeasure = 0 then
  Exit
  else
  begin
    Delete(temp, Length(temp), 1);
    Factor := 0.01 * PercentageMeasure;
  end;
  try
    Value := ReadFloat(temp) * Factor;
    Result := True;
  except
    Result := False;
  end;
end;

class function TCoordinates.GetOnlyValue(const s: string; out Value: Extended): Boolean;
var
  c: TCoordinates;
begin
  c := TCoordinates.Create(s);
  try
    Result := c.GetNextCoordinate(-1, Value);
    if Result then
    if Value < 0 then // keine Prozentwerte erlaubt
    Result := False;
  finally
    c.Free;
  end;
end;

function TCoordinates.GetNextCoordinate(out Value: Extended): Boolean;
begin
  // Akzeptiert keine Prozentwerte
  Result := GetNextCoordinate(0, Value);
end;

class function TCoordinates.GetOnlyValue(const s: string; out Value: Extended; const PercentageMeasure: Extended): Boolean;
var
  c: TCoordinates;
begin
  c := TCoordinates.Create(s);
  try
    Result := c.GetNextCoordinate(PercentageMeasure, Value);
  finally
    c.Free;
  end;
end;

class function TCoordinates.GetOnlyValueDef(const s: string; const Default: Extended): Extended;
begin
  if not GetOnlyValue(s, Result) then
  Result := Default;
end;

class function TCoordinates.GetOnlyValueDef(const s: string; const PercentageMeasure: Extended; const Default: Extended): Extended;
begin
  if not GetOnlyValue(s, Result, PercentageMeasure) then
  Result := Default;
end;

function TCoordinates.IsDelimiter: Boolean;
begin
  if Position > L then
  Result := True
  else
  case Ord(s[Position]) of
    32, 44: Result := True;
    else Result := False;
  end;
end;

function TCoordinates.IsNumber: Boolean;
begin
  if Position > L then
  Result := False
  else
  case Ord(s[Position]) of
    48..57: begin
              Result := True;
              CanMinus := False;
            end;
    45: begin
          Result := CanMinus;
          CanMinus := False;
        end;
    46: begin
          Result := CanDecimal;
          CanMinus := False;
          CanDecimal := False;
        end;
    101: begin // e
           Result := CanExponent;
           CanMinus := True;
           CanDecimal := False;
           CanExponent := False;
         end;
    else Result := False;
  end;
end;

class function TCoordinates.MakeAbsolute(const PercentageMeasure: Extended;
  const Value: Extended): Extended;
begin
  if Value < 0 then
  Result := -Value * PercentageMeasure
  else
  Result := Value;
end;

procedure TCoordinates.ResetNumber;
begin
  CanDecimal := True;
  CanMinus := True;
  CanExponent := True;
end;

{ TPath }

function TPath.GetNextNumber(out Value: Extended): Boolean;
var
  temp: string;
begin
  LastWasRepeat := False;
  ResetNumber();
  try
    while (Position <= L) and IsDelimiter do
    inc(Position);
    while IsNumber do
    begin
      temp := temp + s[Position];
      inc(Position);
    end;
    Value := ReadFloat(temp);
    Result := temp <> '';
  except
    Result := False;
  end;
end;

function TPath.GetNextFlag(out Value: Extended): Boolean;
var
  temp: string;
begin
  LastWasRepeat := False;
  ResetNumber();
  try
    while (Position <= L) and IsDelimiter do
    inc(Position);
    if IsNumber then
    begin
      temp := temp + s[Position];
      inc(Position);
    end;
    Value := ReadFloat(temp);
    Result := temp <> '';
  except
    Result := False;
  end;
end;

function TPath.GetNextType: Char;
begin
  SecondToLastType := LastType;
  Result := #4; // EOT
  ResetNumber();
  while (Position <= L) and IsDelimiter do
  inc(Position);
  if IsNumber then
  begin
    if (LastType = 'm') or (LastType = 'M') then
    Dec(LastType, 1);
    Result := LastType;
    if LastWasRepeat then
    Result := #4;
    LastWasRepeat := True;
  end
  else
  if Position <= L then
  begin
    Result := s[Position];
    inc(Position);
  end;
  LastType := Result;
end;

{ TStyle }

constructor TStyle.Create(const Style: string);
var
  Temp: string;
  Temp2: string;
  Escaping: (esNone = -1, esSingle = $27, esDouble = $22, esBracket = $29);
  i: Integer;
  S: string;
  Importants: TList<string>;
begin
  Properties := Generics.Collections.TDictionary<string,string>.Create();
  Importants := TList<string>.Create();
  try
    Escaping := esNone;
    S := Style + ';';
    for i := 1 to Length(s) do
    if Escaping <> esNone then
    if Ord(s[i]) = Integer(Escaping) then
    begin
      Escaping := esNone;
      Temp := Temp + s[i];
    end
    else
    Temp := Temp + s[i]
    else
    case Ord(s[i]) of
      58: begin
            Temp2 := Temp;
            Temp := '';
          end;
      59: begin
            Temp2 := Trim(Temp2);
            Temp := Trim(Temp);
            if EndsText('!important', Temp) then // ist !important (darf nicht durch nicht !important-Eigenschaften gesetzt werden)
            begin
              Properties.AddOrSetValue(Temp2, Trim(Copy(Temp, 1, Length(Temp) - 10))); // Attribut ohne !important aufnehmen
              if not Importants.Contains(Temp2) then
              begin
                Importants.Add(Temp2); // Attributname wird aufgenommen
              end;
            end
            else
            if not Importants.Contains(Temp2) then
            Properties.AddOrSetValue(Temp2, Temp);
            Temp := '';
            Temp2 := '';
          end;
      $22: begin
             Escaping := esDouble;
             Temp := Temp + s[i];
           end;
      $27: begin
             Escaping := esSingle;
             Temp := Temp + s[i];
           end;
      $28: begin
             Escaping := esBracket;
             Temp := Temp + s[i];
           end;
      else Temp := Temp + s[i];
    end;
  finally
    Importants.Free;
  end;
end;

destructor TStyle.Destroy;
begin
  Properties.Free;
  inherited;
end;

function TStyle.GetProperty(const Attribute: string; out Value: string): Boolean;
begin
  Result := Properties.ContainsKey(Attribute);
  if Result then
  Value := Properties[Attribute];
end;

{ TStyleSplitter }

constructor TStyleSplitter.Create(const S: string; const SplitAtSpace: Boolean);
var
  InStyle: Boolean;
  i: Integer;
  Escaping: (esNone, esSingle, esDouble, esBracket);
begin
  InStyle := False;
  Escaping := esNone;
  for i := 1 to Length(S) do
  if (((S[i] = #32) and SplitAtSpace) or (S[i] = ',')) and (Escaping = esNone) then
  InStyle := False
  else
  begin
    if not InStyle then
    begin
      SetLength(Values, Length(Values)+1);
      InStyle := True;
    end;
    case S[i] of
      '"': begin
             if Escaping = esNone then begin
               Escaping := esDouble;
               Continue; // Anführungszeichen nicht hinzufügen
             end;
             if Escaping = esDouble then
             begin
               Escaping := esNone;
               Continue; // Anführungszeichen nicht hinzufügen
             end;
           end;
      '''': begin
             if Escaping = esNone then begin
               Escaping := esSingle;
               Continue; // Anführungszeichen nicht hinzufügen
             end;
             if Escaping = esSingle then
             begin
               Escaping := esNone;
               Continue; // Anführungszeichen nicht hinzufügen
             end;
           end;
      '(': if Escaping = esNone then Escaping := esBracket;
      ')': begin
             if Escaping = esBracket then Escaping := esNone;
             if SplitAtSpace then InStyle := False;
           end;
    end;
    Values[High(Values)] := Values[High(Values)] + S[i];
  end;
  for i := Low(Values) to High(Values) do
  Values[i] := Trim(Values[i]);
end;

class function TStyleSplitter.GetBracket(const S: string; out Name, Value: string): Boolean;
var
  i: Integer;
begin
  i := Pos('(', S);
  Result := EndsStr(')', s) and (i > 0);
  if Result then
  begin
    Name := Copy(s, 1, i-1);
    Value := Copy(s, i+1, Length(s) - i - 1);
  end;
end;

end.
