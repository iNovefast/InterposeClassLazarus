unit ClassInterpose;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, Graphics;

const
  Regex_Mail  = '[_a-zA-Z\d\-\.]+@[_a-zA-Z\d\-]+(\.[_a-zA-Z\d\-]+)+';
  Regex_URL   =  '(https?:\/\/)?((www|w3)\.)?([-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=]*))';
  Regex_PHONE = '^(?:[6-9]|9[1-9])[0-9]{3}[0-9]{4}$';

  HINT_ERROR  = ' %s Inválido';
  HINT_VALID  = ' %s Válido';

  DEFAULT_ENTER_COLOR    = TColor($00FFFF);
  DEFAULT_EXIT_COLOR     = TColor($FFFFFF);
  DEFAULT_REQUIRED_COLOR = TColor($F0CAA6);
  DEFAULT_ERROR_COLOR    = TColor($0000FF);

type

  TEditModes = (emNone, emMail, emURL, emPhone);

  { TEdit }
  TEdit = class(StdCtrls.TEdit)
  private
    procedure SetEditMode(AValue: TEditModes);
  protected
    FValue   : string;
    FIsValid : boolean;
    FRequerid: Boolean;
    FEditMode: TEditModes;
    FLabel   : TLabel;

    procedure SetLabel;
    procedure KeyPress(var AKey: char); override;

    procedure Change; override;
    procedure SetRequired(AValue: Boolean);
    procedure Validate;

    procedure DoEnter; override;
    procedure DoExit; override;

  private
    property IsValid : boolean    read FIsValid  write FIsValid default True;
    property EditMode: TEditModes read FEditMode write SetEditMode;
  public
    procedure SetEmailMode;
    procedure SetURLMode;
    procedure SetPhoneMode;

    property Requerid: Boolean read FRequerid write SetRequired;
  end;

implementation
  uses RegExpr;

function Description(const AEditMode: TEditModes): string;
begin
  case AEditMode of
    emURL   : Result := 'URL';
    emMail  : Result := 'E-mail';
    emPhone : Result := 'Telefone';
  else
    Result := '';
  end;
end;

function RegexValid(const AText: string; const AExpression: string): boolean;
var
  LExpr: TRegExpr;
begin
  try
    LExpr := TRegExpr.Create;
    LExpr.Expression := AExpression;
    Result := LExpr.Exec(AText);
  finally
    LExpr.Free;
  end;
end;

procedure TEdit.SetEditMode(AValue: TEditModes);
begin
  if FEditMode = AValue then
     Exit;

  FEditMode := AValue;

  if Assigned(Self.FLabel) then
    Self.FLabel.Caption := '&' + Description(AValue);
end;

procedure TEdit.SetLabel;
var
  FComponentIndex: Integer;
begin
  for FComponentIndex := 0 to Pred(Self.Parent.ComponentCount) do
  begin
    if Self.Parent.Components[FComponentIndex] is TLabel then
    begin
      if TLabel(Self.Parent.Components[FComponentIndex]).FocusControl = Self then
      begin
        Self.FLabel := TLabel(Self.Parent.Components[FComponentIndex]);
        Break;
      end;
    end;
  end;
end;

{ TEdit }
procedure TEdit.KeyPress(var AKey: char);
begin
  inherited KeyPress(AKey);

  if EditMode in [emMail..emURL] then
    if CharInSet(AKey, ['0'..'9', #44, #27, #10]) then
      Akey := #0;

  if EditMode = emPhone then
    if not CharInSet(AKey, ['0'..'9', #8, #27, #44]) then
      Akey := #0;

  FValue := Self.Text + AKey;

  inherited;

end;

procedure TEdit.Change;
begin
  Validate;

  inherited Change;
end;

procedure TEdit.SetRequired(AValue: Boolean);
begin
  if FRequerid = AValue then
    Exit;

  FRequerid := AValue;

  if FRequerid then
  begin
    Self.Color := DEFAULT_REQUIRED_COLOR;

    if Assigned(Self.FLabel) then
    begin
      Self.FLabel.Caption := '* ' + Self.FLabel.Caption;
      Self.FLabel.Font.Style := [fsBold];
    end;
  end;
end;

procedure TEdit.Validate;
var
  LExpression: string;
begin
  Self.IsValid := True;
  try

    if Self.Text = '' then
       Exit;

    case Self.EditMode of
      emMail : LExpression := Regex_Mail;
      emURL  : LExpression := Regex_URL;
      emPhone: LExpression := Regex_PHONE;
    else
      Exit;
    end;

    Self.IsValid := RegexValid(Self.Text, LExpression);
  finally
    if Self.IsValid then
    begin
      Self.Color := DEFAULT_EXIT_COLOR;
      Self.Hint  := Format(HINT_VALID, [Description(EditMode)]);
    end
    else
    begin
      Self.Color := DEFAULT_ERROR_COLOR;
      Self.Hint  := Format(HINT_ERROR, [Description(EditMode)]);
    end;
  end;
end;

procedure TEdit.DoEnter;
begin
  if EditMode <> emNone then
  begin
    if Self.Text = '' then
    begin
      Self.TextHint := 'Informe o ' + Description(Self.EditMode);
      Self.Hint     := 'Informe um ' + Description(Self.EditMode) + ' válido';
    end;
  end;

  inherited DoEnter;
end;

procedure TEdit.DoExit;
begin
  if (Self.EditMode <> emNone) and (Self.Text <> '') and (not Self.IsValid) then
    Self.Color := DEFAULT_ERROR_COLOR
  else if Self.Requerid then
    Self.Color := DEFAULT_REQUIRED_COLOR
  else
    Self.Color := DEFAULT_EXIT_COLOR;

  Self.TextHint := '';

  if Self.Text <> '' then
    Self.Hint := '';

  inherited DoExit;
end;

procedure TEdit.SetEmailMode;
begin
  SetLabel;

  Self.EditMode := emMail;
  Self.ShowHint := True;
end;

procedure TEdit.SetURLMode;
begin
  SetLabel;

  Self.EditMode := emURL;
  Self.ShowHint := True;
end;

procedure TEdit.SetPhoneMode;
begin
  SetLabel;

  Self.EditMode := emPhone;
  Self.ShowHint := True;
end;

end.
