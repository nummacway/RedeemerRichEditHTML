unit RedeemerRichEditHTML;

//
//  RedeemerRichEditHTML
//  Kleine Unit, die zwischen HTML und RichEdit konvertiert.
//  Soll primär ihren eigenen Output wieder lesen können.
//

interface

uses
  ComCtrls;

procedure HTMLToRichEdit(const HTML: string; RichEdit: TRichEdit);
function RichEditToHTML(const RichEdit: TRichEdit): string;
function HTMLToPlaintext(const HTML: string; const UseUnicodeForStyle: Boolean): string;
function UnicodeSansSerifBold(const s: string): string;
function UnicodeSansSerifItalic(const s: string): string;
function UnicodeSansSerifBoldItalic(const s: string): string;

type
  TRichEditHelper = class helper for TRichEdit
    private
    procedure SetSelTextKeepSelAttributes(const Value: string);
    public
      property SelTextKeepSelAttributes: string write SetSelTextKeepSelAttributes; // Behebt einen Fehler, durch den SelAttributes entfernt werden, wenn Value auf #13#10 oder #11 endet (nur für Style und Color implementiert aktuell)
  end;

implementation

uses
  RedeemerHTML, Generics.Collections, Graphics, RedeemerSVGHelpers, StrUtils,
  SysUtils, RedeemerHypertextColors, RedeemerHypertextColorsCSS,
  RedeemerEntities, RedeemerHTMLHelpers, Classes;

type
  TSpanStyle = record
    Color: TColor;
  end;

  // Zwischenformat für RichText zu HTML
  TFragment = class
    Tag: string;
    Pos: Integer;
    Text: string;
    EndPos: Integer;
  end;

  // Zwischenformat zur Optimierung von Verschachtelung
  TFormat = class
    Tag: string;
    Param: string;
  end;

const
  IndexNumbers = #$30#$31#$32#$33#$34#$35#$36#$37#$38#$39;
  IndexLatin   = #$41#$42#$43#$44#$45#$46#$47#$48#$49#$4A#$4B#$4C#$4D#$4E#$4F#$50#$51#$52#$53#$54#$55#$56#$57#$58#$59#$5A#$61#$62#$63#$64#$65#$66#$67#$68#$69#$6A#$6B#$6C#$6D#$6E#$6F#$70#$71#$72#$73#$74#$75#$76#$77#$78#$79#$7A;
  IndexDotless = #$131#$237;
  IndexGreek   = #$391#$392#$393#$394#$395#$396#$397#$398#$399#$39A#$39B#$39C#$39D#$39E#$39F#$3A0#$3A1#$3F4#$3A3#$3A4#$3A5#$3A6#$3A7#$3A8#$3A9#$2207#$3B1#$3B2#$3B3#$3B4#$3B5#$3B6#$3B7#$3B8#$3B9#$3BA#$3BB#$3BC#$3BD#$3BE#$3BF#$3C0#$3C1#$3C2#$3C3#$3C4#$3C5#$3C6#$3C7#$3C8#$3C9#$2202#$3F5#$3D1#$3F0#$3D5#$3F1#$3D6;
  IndexDigamma = #$3DC#$3DD;

procedure HTMLToRichEdit(const HTML: string; RichEdit: TRichEdit);
var
  XML: TRedeemerHTML;
  CurrentSpanStyle: TSpanStyle;
  SpanStyles: TStack<TSpanStyle>;
  Style: TStyle;
  Temp: string;
  LetzterText: string;
  LetzterNichtLeererText: string;
  OnChangeOld: TNotifyEvent;
procedure SetStyle();
begin
  RichEdit.SelAttributes.Color := CurrentSpanStyle.Color;
end;
begin
  RichEdit.Clear;
  XML := TRedeemerHTML.Create(HTML);
  SpanStyles := TStack<TSpanStyle>.Create();
  OnChangeOld := RichEdit.OnSelectionChange;
  try
    RichEdit.OnSelectionChange := nil;
    CurrentSpanStyle.Color := clBlack;
    SetStyle();
    repeat
      LetzterText := XML.GetTextAndSkip();
      if LetzterText <> '' then
      LetzterNichtLeererText := LetzterText;
      {if XML.CurrentTag = 'ul' then // Blockelemente: Letzter Absatz wird ignoriert
      if EndsStr(XML.NewLine, LetzterNichtLeererText) then
      Delete(LetzterText, Length(LetzterText), 1);   }
      if RichEdit.Paragraph.Numbering = nsBullet then
      RichEdit.SelText := LetzterText
      else
      RichEdit.SelTextKeepSelAttributes := StringReplace(LetzterText, #11, #13#10, [rfReplaceAll]);
      if XML.Done then
      Break;
      // Standard-Stile
      if XML.CurrentTag = 'b' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style + [fsBold]
      else
      if XML.CurrentTag = '/b' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style - [fsBold]
      else
      if XML.CurrentTag = 'i' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style + [fsItalic]
      else
      if XML.CurrentTag = '/i' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style - [fsItalic]
      else
      if XML.CurrentTag = 'u' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style + [fsUnderline]
      else
      if XML.CurrentTag = '/u' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style - [fsUnderline]
      else
      if XML.CurrentTag = 's' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style + [fsStrikeOut]
      else
      if XML.CurrentTag = '/s' then
      RichEdit.SelAttributes.Style := RichEdit.SelAttributes.Style - [fsStrikeOut]
      else
      // Span - derzeit limitiert auf Farben
      if XML.CurrentTag = 'span' then
      begin
        SpanStyles.Push(CurrentSpanStyle);
        Style := TStyle.Create(XML.GetAttributeDef('style', ''));
        try
          if Style.GetProperty('color', Temp) then
          HTMLToColor(Temp, CurrentSpanStyle.Color, RedeemerHypertextColorsCSS.CSSColors);
          SetStyle();
        finally
          Style.Free();
        end;
      end
      else
      if XML.CurrentTag = '/span' then
      begin
        CurrentSpanStyle := SpanStyles.Pop();
        SetStyle();
      end
      else
      if XML.CurrentTag = 'li' then
      begin
        if not EndsStr(XML.NewLine, LetzterNichtLeererText) then
        RichEdit.SelText := #13#10;
        RichEdit.Paragraph.Numbering := nsBullet;
      end
      else
      if XML.CurrentTag = '/ul' then
      begin
        RichEdit.SelText := #13#10;
        RichEdit.Paragraph.Numbering := nsNone;
      end
      else
    until XML.Done;
  finally
    XML.Free();
    SpanStyles.Free();
    RichEdit.OnSelectionChange := OnChangeOld;
    if Assigned(OnChangeOld) then
    RichEdit.OnSelectionChange(RichEdit);
  end;
end;

function RichEditToHTML(const RichEdit: TRichEdit): string;
var
  Content: TList<TFragment>;
  b,i,u,s: Boolean;
  color: TColor;
  Bullets: Boolean;
  j: Integer;
  length: Integer;
  OnChangeOld: TNotifyEvent;
function AddFragment: TFragment;
begin
  Result := TFragment.Create;
  Result.Pos := j;
  Result.EndPos := -1;
  Content.Add(Result);
end;
procedure FindEnd(const Fragment: TFragment; const ListIndex: Integer);
var
  i: Integer;
  s: string;
begin
  if not (Fragment.Tag = '') then
  if Fragment.Tag[1] = '/' then
  begin
    Fragment.EndPos := 9000;// Move ending tags before opening tags - ehm no, we won't reorder them at all, because the nesting function will find the mistakes somewhen
    Exit;
  end;
  if Pos('=', Fragment.Tag) > 0 then
  s := '/' + Copy(Fragment.Tag, 1, Pos('=', Fragment.Tag) - 1)
  else
  s := '/' + Fragment.Tag;
  for i := ListIndex + 1 to Content.Count - 1 do
  if TFragment(Content.Items[i]).Tag = s then
  begin
    Fragment.EndPos := i;
    Exit;
  end;
end;
procedure OptimizeFindEndTags();
var
  j: Integer;
  b: Boolean;
begin
  b := False;
  for j := 0 to Content.Count - 2 do
  begin
    if not b then
    TFragment(Content.Items[j]).EndPos := -1;
    if TFragment(Content.Items[j]).Pos = TFragment(Content.Items[j + 1]).Pos then
    begin
      if not b then
      FindEnd(TFragment(Content.Items[j]), j);
      FindEnd(TFragment(Content.Items[j+1]), j);
      b := True;
    end
    else
    b := False;
  end;
end;
function IsBlock(m: Integer): Boolean;
begin
  if (TFragment(Content[m]).Tag = 'li') or
     (TFragment(Content[m]).Tag = 'ul') then
  Result := True
  else
  Result := False;
end;
procedure OptimizeSortStartTags();
var
  j, k, l, m: Integer;
  Bubble: TFragment;
  b: Boolean;
begin
  k := 0;
  for j := 0 to Content.Count - 2 do
  begin
    b := False;
    if (TFragment(Content.Items[j]).Pos = TFragment(Content.Items[j + 1]).Pos) then
    if (not (TFragment(Content.Items[j]).Tag = '')) and (not (TFragment(Content.Items[j + 1]).Tag = '')) then
    if {MoveEndingTags or} (not (TFragment(Content.Items[j]).Tag[1] = '/') and not (TFragment(Content.Items[j+1]).Tag[1] = '/')) then
    b := True;

    if b then
    begin
      inc(k);
    end
    else
    begin
      // Bubblesort
      if k > 0 then
      begin
        for l := j - k - 1 to j do
        for m := j - k to j - 1 do
        begin
          // Blockelemente müssen vor Inline-Elementen starten
          if (IsBlock(m+1) and not IsBlock(m)) or (TFragment(Content.Items[m]).EndPos < TFragment(Content.Items[m+1]).EndPos) then
          begin
            Bubble := Content.Items[m];
            Content.Items[m] := Content.Items[m+1];
            Content.Items[m+1] := bubble;
          end;
        end;
      end;
      k := 0;
    end;
  end;
end;
function OptimizeFixNestings(): Boolean;
var
  Stack: TObjectStack<TFormat>;
  i: Integer;
  added: Integer;
function InsertFragment(const Index: Integer; const Pos: Integer): TFragment;
begin
  Result := TFragment.Create;
  Result.Pos := Pos;
  Result.EndPos := -1;
  Content.Insert(Index, Result);
end;
procedure PushFormat(const TagData: string);
var
  Result: TFormat;
begin
  if TagData = '' then
  Exit;
  Result := TFormat.Create;
  if Pos('=', TagData) > 0 then
  begin
    Result.Tag := Copy(TagData, 1, Pos('=', TagData) - 1);
    Result.Param := RightStr(TagData, System.Length(TagData) - System.Length(Result.Tag) - 1)
  end
  else
  Result.Tag := TagData;
  Stack.Push(Result);
end;
begin
  Result := False;
  added := 0;
  Stack := TObjectStack<TFormat>.Create;
  try
    for i := 0 to Content.Count - 1 do
    if StartsStr('/', TFragment(Content.Items[i]).Tag) then
    begin
      if TFragment(Content.Items[i]).Tag = '/' + TFormat(Stack.Peek()).Tag then
      Stack.Pop()
      else
      begin
        repeat
          InsertFragment(i, TFragment(Content.Items[i+added]).Pos).Tag := '/' + TFormat(Stack.Peek()).Tag;
          inc(added);
          // Endfragment kommt ganz ans Ende, wird später richtig eingeordnet
          InsertFragment(i+added*2, TFragment(Content.Items[i+added-1]).Pos).Tag := TFormat(Stack.Peek()).Tag + IfThen(TFormat(Stack.Peek()).Param = '', '', '=' + TFormat(Stack.Peek()).Param);
          Stack.Pop();
        until TFragment(Content.Items[i+added]).Tag = '/' + TFormat(Stack.Peek()).Tag;
        Result := True;
        Exit;
      end;
    end
    else
    PushFormat(TFragment(Content.Items[i]).Tag);
  finally
    Stack.Free;
  end;
end;
procedure OptimizeDeleteEmptyTags();
procedure DeleteFragment(const Index: Integer);
var
  i: Integer;
begin
  Content[Index].Free();
  Content.Delete(Index);
  for i := Index to Content.Count - 1 do
  dec(TFragment(Content.Items[i]).EndPos);
end;
var
  i: Integer;
begin
  i := 0;
  repeat
    if TFragment(Content.Items[i]).EndPos > -1 then
    if TFragment(Content.Items[i]).Tag <> '' then
    if not StartsStr('/', TFragment(Content.Items[i]).Tag) then
    if TFragment(Content.Items[TFragment(Content.Items[i]).EndPos]).Pos = TFragment(Content.Items[i]).Pos then
    begin
      DeleteFragment(TFragment(Content.Items[i]).EndPos);
      DeleteFragment(i);
    end;
    inc(i);
  until i >= Content.Count - 1;
end;
procedure ResetInline();
begin
  if b then
  AddFragment().Tag := '/b';
  if i then
  AddFragment().Tag := '/i';
  if u then
  AddFragment().Tag := '/u';
  if s then
  AddFragment().Tag := '/s';
  if color <> clBlack then
  AddFragment().Tag := '/color';
  b := False;
  i := False;
  u := False;
  s := False;
  color := clBlack;
end;
begin
  OnChangeOld := RichEdit.OnSelectionChange;
  Content := TList<TFragment>.Create();
  try
    RichEdit.OnSelectionChange := nil;
    b := False;
    i := False;
    u := False;
    s := False;
    bullets := False;
    color := clBlack;
    j := 0;
    length := System.Length(RichEdit.Text);
    AddFragment();

    //
    // BASIC DATA COLLECTION
    //
    if Length > 0 then
    repeat
      RichEdit.SelStart := j;
      RichEdit.SelLength := 1;
      // Align
      if (RichEdit.Paragraph.Numbering = nsBullet) <> bullets then
      begin
        bullets := RichEdit.Paragraph.Numbering = nsBullet;
        if bullets then
        begin
          ResetInline();
          AddFragment().Tag := 'ul';
          AddFragment().Tag := 'li';
        end
        else
        begin
          //AddFragment().Tag := '/li';
          //AddFragment().Tag := '/ul';
          TFragment(Content.Last).Tag := '/ul';
        end;
      end;
      // Bold
      if (fsBold in RichEdit.SelAttributes.Style) <> b then
      begin
        if b then
        AddFragment().Tag := '/b'
        else
        AddFragment().Tag := 'b';

        b := (fsBold in RichEdit.SelAttributes.Style);
      end;
      // Italic
      if (fsItalic in RichEdit.SelAttributes.Style) <> i then
      begin
        if i then
        AddFragment().Tag := '/i'
        else
        AddFragment().Tag := 'i';

        i := (fsItalic in RichEdit.SelAttributes.Style);
      end;
      // Underline
      if (fsUnderline in RichEdit.SelAttributes.Style) <> u then
      begin
        if u then
        AddFragment().Tag := '/u'
        else
        AddFragment().Tag := 'u';

        u := (fsUnderline in RichEdit.SelAttributes.Style);
      end;
      // Underline
      if (fsStrikeOut in RichEdit.SelAttributes.Style) <> s then
      begin
        if s then
        AddFragment().Tag := '/s'
        else
        AddFragment().Tag := 's';

        s := (fsStrikeOut in RichEdit.SelAttributes.Style);
      end;
      // Color
      if RichEdit.SelAttributes.Color <> color then
      begin
        if color <> clBlack then AddFragment().Tag := '/color';
        if RichEdit.SelAttributes.Color <> clBlack then AddFragment().Tag := 'color=' + ColorToHTML(RichEdit.SelAttributes.Color);
        color := RichEdit.SelAttributes.Color;
      end;

      if not (TFragment(Content.Last).Tag = '') then
      AddFragment();

      if RichEdit.SelText <> #10 then
      if RichEdit.SelText = #13 then
      begin
        if Bullets then
        begin
          AddFragment().Tag := '/li';
          AddFragment().Tag := 'li';
        end
        else
        TFragment(Content.Last).Text := TFragment(Content.Last).Text + #11;
      end
      else
      TFragment(Content.Last).Text := TFragment(Content.Last).Text + RichEdit.SelText;

      inc(j);
    until j = length;
    //
    // RESET STUFF AT THE END
    //
    ResetInline();
    if bullets then
    begin
      AddFragment().Tag := '/li';
      AddFragment().Tag := '/ul';
    end;

    //
    // OPTIMIZATION
    //
    // We repeat these steps until the pushdown automaton OptimizeFixNestings
    // finally accepts the input and does not have to fix anything.
    //
    repeat
      OptimizeFindEndTags();
      OptimizeSortStartTags();
      // b indicates if the pushdown automaton OptimizeFixNestings found at least
      // one error, so the content was incorrect when the function started
      b := OptimizeFixNestings();
      OptimizeFindEndTags();
      OptimizeDeleteEmptyTags();
    until not b;

    //
    // OUTPUT
    //
    Result := '';
    for j := 0 to Content.Count - 1 do
    with TFragment(Content.Items[j]) do
    begin
      Text := StringReplace(EscapeToHTML(Text, False), '&#11;', '<br>', [rfReplaceAll]);
      if Tag = '' then
      Result := Result + Text
      else
      begin
        if StartsStr('color=', Tag) then // Color-Starttag zu SPAN umwandeln
        Result := Result + '<span style="color:' + Copy(Tag, 7, High(Integer)) + '">' + Text
        else
        if Tag = '/color' then // Color-Endtag zu SPAN umwandeln
        Result := Result + '</span>' + Text
        else
        if Tag = 'ul' then // kein Platz um Aufzählungen herum
        Result := Result + '<ul style="margin:0">' + Text
        else
        Result := Result + '<' + Tag + '>' + Text;
      end;
    end;
    Result := StringReplace(Result, #11, '<br>', [rfReplaceAll]);
  finally
    for j := Content.Count - 1 downto 0 do
    Content[j].Free();
    Content.Free;
    RichEdit.OnSelectionChange := OnChangeOld;
  end;
end;

function HTMLToPlaintext(const HTML: string; const UseUnicodeForStyle: Boolean): string;
const
  Bullet = '•  ';
var
  XML: TRedeemerHTML;
  LetzterText, LetzterNichtLeererText: string;
  IsBold, IsItalic: Boolean;
begin
  Result := '';
  IsBold := False;
  IsItalic := False;
  XML := TRedeemerHTML.Create(HTML);
  try
    repeat
      LetzterText := XML.GetTextAndSkip();
      if XML.CurrentTag = 'ul' then // Blockelemente: Letzter Absatz wird ignoriert
      if EndsStr(XML.NewLine, LetzterText) then
      Delete(LetzterText, Length(LetzterText), 1);

      if LetzterText <> '' then
      LetzterNichtLeererText := LetzterText;

      if XML.CurrentTag = 'li' then
      if EndsStr(XML.NewLine, LetzterNichtLeererText) then
      LetzterText := Bullet + LetzterText
      else
      LetzterText := XML.NewLine + Bullet + LetzterText
      else
      LetzterText := LetzterText;

      if IsBold and UseUnicodeForStyle then
      if IsItalic then
      Result := Result + UnicodeSansSerifBoldItalic(LetzterText)
      else
      Result := Result + UnicodeSansSerifBold(LetzterText)
      else
      if IsItalic and UseUnicodeForStyle then
      Result := Result + UnicodeSansSerifItalic(LetzterText)
      else
      Result := Result + LetzterText;

      if XML.Done then
      Break;

      // Standard-Stile
      if XML.CurrentTag = 'b' then
      IsBold := True
      else
      if XML.CurrentTag = '/b' then
      IsBold := False
      else
      if XML.CurrentTag = 'i' then
      IsItalic := True
      else
      if XML.CurrentTag = '/i' then
      isItalic := False
      else
      if XML.CurrentTag = '/ul' then
      Result := Result + XML.NewLine;
    until XML.Done;
  finally
    XML.Free();
  end;
  Result := StringReplace(Result, #11, #13#10, [rfReplaceAll]);
end;

function DoUnicode(const s: string; const Indexes: string; const NewChars: array of Cardinal): string;
var
  i: Integer;
  Index: Byte;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    Index := Pos(s[i], Indexes);
    if Index = 0 then
    Result := Result + s[i]
    else
    Result := Result + UCS4Chr(NewChars[Index-1]);
  end;
end;

function UnicodeSansSerifBold(const s: string): string;
const
  NewChars: array[0..119] of Cardinal = ($1D7EC, $1D7ED, $1D7EE, $1D7EF, $1D7F0, $1D7F1, $1D7F2, $1D7F3, $1D7F4, $1D7F5, // Ziffern
                                         $1D5D4, $1D5D5, $1D5D6, $1D5D7, $1D5D8, $1D5D9, $1D5DA, $1D5DB, $1D5DC, $1D5DD, $1D5DE, $1D5DF, $1D5E0, $1D5E1, $1D5E2, $1D5E3, $1D5E4, $1D5E5, $1D5E6, $1D5E7, $1D5E8, $1D5E9, $1D5EA, $1D5EB, $1D5EC, $1D5ED, // lateinische Großbuchstaben
                                         $1D5EE, $1D5EF, $1D5F0, $1D5F1, $1D5F2, $1D5F3, $1D5F4, $1D5F5, $1D5F6, $1D5F7, $1D5F8, $1D5F9, $1D5FA, $1D5FB, $1D5FC, $1D5FD, $1D5FE, $1D5FF, $1D600, $1D601, $1D602, $1D603, $1D604, $1D605, $1D606, $1D607, // lateinische Kleinbuchstaben
                                         $1D756, $1D757, $1D758, $1D759, $1D75A, $1D75B, $1D75C, $1D75D, $1D75E, $1D75F, $1D760, $1D761, $1D762, $1D763, $1D764, $1D765, $1D766, $1D767, $1D768, $1D769, $1D76A, $1D76B, $1D76C, $1D76D, $1D76E, // griechische Großbuchstaben
                                         $1D76F, // Nabla
                                         $1D770, $1D771, $1D772, $1D773, $1D774, $1D775, $1D776, $1D777, $1D778, $1D779, $1D77A, $1D77B, $1D77C, $1D77D, $1D77E, $1D77F, $1D780, $1D781, $1D782, $1D783, $1D784, $1D785, $1D786, $1D787, $1D788, $1D789, $1D78A, $1D78B, $1D78C, $1D78D, $1D78E, $1D78F); // griechische Kleinbuchstaben
begin
  Result := DoUnicode(s, IndexNumbers + IndexLatin + IndexGreek, NewChars);
end;

function UnicodeSansSerifItalic(const s: string): string;
const
  NewChars: array[0..51] of Cardinal = ($1D608, $1D609, $1D60A, $1D60B, $1D60C, $1D60D, $1D60E, $1D60F, $1D610, $1D611, $1D612, $1D613, $1D614, $1D615, $1D616, $1D617, $1D618, $1D619, $1D61A, $1D61B, $1D61C, $1D61D, $1D61E, $1D61F, $1D620, $1D621, // lateinische Großbuchstaben
                                        $1D622, $1D623, $1D624, $1D625, $1D626, $1D627, $1D628, $1D629, $1D62A, $1D62B, $1D62C, $1D62D, $1D62E, $1D62F, $1D630, $1D631, $1D632, $1D633, $1D634, $1D635, $1D636, $1D637, $1D638, $1D639, $1D63A, $1D63B); // lateinische Kleinbuchstaben
begin
  Result := DoUnicode(s, IndexLatin, NewChars);
end;

function UnicodeSansSerifBoldItalic(const s: string): string;
const
  NewChars: array[0..119] of Cardinal = ($1D7EC, $1D7ED, $1D7EE, $1D7EF, $1D7F0, $1D7F1, $1D7F2, $1D7F3, $1D7F4, $1D7F5, // Ziffern (nur fett, nicht kursiv)
                                         $1D63C, $1D63D, $1D63E, $1D63F, $1D640, $1D641, $1D642, $1D643, $1D644, $1D645, $1D646, $1D647, $1D648, $1D649, $1D64A, $1D64B, $1D64C, $1D64D, $1D64E, $1D64F, $1D650, $1D651, $1D652, $1D653, $1D654, $1D655, // lateinische Großbuchstaben
                                         $1D656, $1D657, $1D658, $1D659, $1D65A, $1D65B, $1D65C, $1D65D, $1D65E, $1D65F, $1D660, $1D661, $1D662, $1D663, $1D664, $1D665, $1D666, $1D667, $1D668, $1D669, $1D66A, $1D66B, $1D66C, $1D66D, $1D66E, $1D66F, // lateinische Kleinbuchstaben
                                         $1D790, $1D791, $1D792, $1D793, $1D794, $1D795, $1D796, $1D797, $1D798, $1D799, $1D79A, $1D79B, $1D79C, $1D79D, $1D79E, $1D79F, $1D7A0, $1D7A1, $1D7A2, $1D7A3, $1D7A4, $1D7A5, $1D7A6, $1D7A7, $1D7A8, // griechische Großbuchstaben
                                         $1D7A9, // Nabla
                                         $1D7AA, $1D7AB, $1D7AC, $1D7AD, $1D7AE, $1D7AF, $1D7B0, $1D7B1, $1D7B2, $1D7B3, $1D7B4, $1D7B5, $1D7B6, $1D7B7, $1D7B8, $1D7B9, $1D7BA, $1D7BB, $1D7BC, $1D7BD, $1D7BE, $1D7BF, $1D7C0, $1D7C1, $1D7C2, $1D7C3, $1D7C4, $1D7C5, $1D7C6, $1D7C7, $1D7C8, $1D7C9); // griechische Kleinbuchstaben
begin
  Result := DoUnicode(s, IndexNumbers + IndexLatin + IndexGreek, NewChars);
end;

{ TRichEditHelper }

procedure TRichEditHelper.SetSelTextKeepSelAttributes(const Value: string);
var
  Style: TFontStyles;
  Color: TColor;
begin
  Style := SelAttributes.Style;
  Color := SelAttributes.Color;
  SelText := Value;
  SelAttributes.Color := Color;
  SelAttributes.Style := Style;
end;

end.
