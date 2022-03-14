unit RedeemerHTML;

interface

uses
  RedeemerXML;

type
  TRedeemerHTML = class(TRedeemerXML)
    public
      function GetTextAndSkip(): string;
      const
        NewLine = #11;
  end;

implementation

uses
  RedeemerEntities, StrUtils, SysUtils;

function TRedeemerHTML.GetTextAndSkip: string;
var
  i: Integer;
begin
  if (CurrentTag = 'br') or (CurrentTag = 'br/') then
  begin
    Result := NewLine;
  end
  else
  begin
    Result := '';
    if IsSelfClosing then
    begin
      GoToAndGetNextTag();
      Exit; // inhaltslos und nicht <br>
    end;
  end;
  repeat
    i := PosEx('>', Text, Position) + 1;
    GoToAndGetNextTag();
    if Done then // wir sind am Ende
    begin
      Result := Result + RemoveEntities(Copy(Text, i, TextLength - i));
      // Rest
      Break;
    end
    else
    begin
      Result := Result + RemoveEntities(Copy(Text, i, Position - i));
      if (CurrentTag = 'br') or (CurrentTag = 'br/') then
      Result := Result + NewLine
      else
      Break;
    end;
  until False;
  Result := Clean(Result, True);
  // Von und nach Absätzen keine Leerzeichen zulassen
  Result := StringReplace(Result, NewLine + #32, NewLine, [rfReplaceAll]);
  Result := StringReplace(Result, #32 + NewLine, NewLine, [rfReplaceAll]);
end;

end.
