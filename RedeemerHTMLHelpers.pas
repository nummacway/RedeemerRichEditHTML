unit RedeemerHTMLHelpers;

interface

uses
  Graphics;

function ColorToHTML(const Color: TColor): string;
function EscapeToHTML(const s: string; const ToAscii: Boolean = True): string;
function EscapeToHTML2(const s: string): string; // inkl. <br> für #$13, #$11 - funktioniert auch mit Texten aus der Datenbank (auch aus Fepro, die sind #13#10)
function EscapeToHTML3(const s: string): string; // inkl. <br> für #$10, #$11 - wird derzeit nicht verwendet

implementation

uses
  SysUtils;

function ColorToHTML(const Color: TColor): string;
var
  temp: string;
begin
  // Umwandeln von Farben in HTML- bzw. CSS-Farbnamen, stammt aus meiner eigenen BBcode-Unit
  case Color of // zuerst Farben, deren Name kürzer ist als der Farbcode
    $00FFFFF0: Result := 'azure';
    $00DCF5F5: Result := 'beige';
    $00C4E4FF: Result := 'bisque';
    $002A2AA5: Result := 'brown';
    $00507FFF: Result := 'coral';
    $0000D7FF: Result := 'gold';
    $00808080: Result := 'gray';
    $00008000: Result := 'green';
    $0082004B: Result := 'indigo';
    $00F0FFFF: Result := 'ivory';
    $008CE6F0: Result := 'khaki';
    $00E6F0FA: Result := 'linen';
    $00000080: Result := 'maroon';
    $00800000: Result := 'navy';
    $00008080: Result := 'olive';
    $0000A5FF: Result := 'orange';
    $00D670DA: Result := 'orchid';
    $003F85CD: Result := 'peru';
    $00CBC0FF: Result := 'pink';
    $00DDA0DD: Result := 'plum';
    $00800080: Result := 'purple';
    $000000FF: Result := 'red';
    $007280FA: Result := 'salmon';
    $002D52A0: Result := 'sienna';
    $00C0C0C0: Result := 'silver';
    $00FAFAFF: Result := 'snow';
    $008CB4D2: Result := 'tan';
    $00808000: Result := 'teal';
    $004763FF: Result := 'tomato';
    $00EE82EE: Result := 'violet';
    $00B3DEF5: Result := 'wheat';
    else
    begin
      temp := IntToHex(Cardinal(Color), 8);
      Result := Lowercase(temp[7] + temp[8] + temp[5] + temp[6] + temp[3] + temp[4]);
      if (Result[1] = Result[2]) and
         (Result[3] = Result[4]) and
         (Result[5] = Result[6]) then
      Result := '#' + Result[1] + Result[3] + Result[5]
      else
      Result := '#' + Result;
    end;
  end;
end;

function EscapeToHTML(const s: string; const ToAscii: Boolean = True): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
  case Word(Ord(s[i])) of
    $3C: Result := Result + '&lt;';
    $3E: Result := Result + '&gt;';
    $22: Result := Result + '&quot;';
    $26: Result := Result + '&amp;';
    $20, $21, $23..$25, $27..$3B, $3D, $3F..$7F:
      // unkritische ASCII-Zeichen
      Result := Result + s[i];
    $FFFE: ; // Not a character
    $D800..$DBFF:
      // High Surrogates, nur speichern, wenn nicht als Entity zu speichern
      if not ToAscii then
      Result := Result + s[i];
    $DC00..$DFFF:
      // Low Surrogates
      if ToAscii then
      begin
        if i > 1 then // String kann nicht mit Low Surrogate beginnen, da davor ein High Surrogate stehen muss
        Result := Result + '&#' + IntToStr((Integer(Ord(s[i - 1]) and $3FF) shl 10) or Ord(s[i]) + $10000) + ';'
      end
      else
      Result := Result + s[i];
    else
      // UCS-2
      if ToAscii then
      Result := Result + '&#' + IntToStr(Ord(s[i])) + ';'
      else
      Result := Result + s[i];
  end;
end;

function EscapeToHTML2(const s: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
  case Word(Ord(s[i])) of
    $3C: Result := Result + '&lt;';
    $3E: Result := Result + '&gt;';
    $22: Result := Result + '&quot;';
    $26: Result := Result + '&amp;';
    $d, $b: Result := Result + '<br>';
    $a, $FFFE: ; // Not a character
    else
      Result := Result + s[i];
  end;
end;

function EscapeToHTML3(const s: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
  case Word(Ord(s[i])) of
    $3C: Result := Result + '&lt;';
    $3E: Result := Result + '&gt;';
    $22: Result := Result + '&quot;';
    $26: Result := Result + '&amp;';
    $a, $b: Result := Result + '<br>';
    $d, $FFFE: ; // Not a character
    else
      Result := Result + s[i];
  end;
end;

end.
