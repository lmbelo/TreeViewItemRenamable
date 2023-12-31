unit FMX.TreeView.Item;

interface

uses
  System.UITypes, System.Classes, System.SysUtils,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.TreeView, FMX.Edit;

type
  TOnTreeViewItemRename = procedure(Sender: TObject; const AOldName: string; var ANewName: string) of object;
  TTreeViewItem = class(FMX.TreeView.TTreeViewItem)
  private
    FText: TControl;
    FRename: TCustomEdit;
    FRenamable: boolean;
    FLazyInput: boolean;
    FRenaming: boolean;
    FLastClick: TDateTime;
    FOnRename: TOnTreeViewItemRename;
  private
    procedure UpdateRenameEditVisibility();
    procedure UpdateRenameEditSize();
    procedure DoStartRenaming();
    procedure DoEndRenaming(const ACancel: boolean = false);
  protected
    procedure ApplyStyle; override;
    procedure FreeStyle; override;
    procedure Click; override;
    procedure DblClick; override;
    procedure OnRenameKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure OnRenameChangeTracking(Sender: TObject);
    procedure OnRenameExit(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;

    function CanRename(): boolean;
    procedure Rename();

    property Renaming: boolean read FRenaming;
  published
    property Renamable: boolean read FRenamable write FRenamable default true;
    //Doesn't trigger input on double click - it requires a longer interval...
    property LazyInput: boolean read FLazyInput write FLazyInput;
    property OnRename: TOnTreeViewItemRename read FOnRename write FOnRename;
  end;

implementation

uses
  System.Math, System.DateUtils;

{ TTreeViewItem }

constructor TTreeViewItem.Create(AOwner: TComponent);
begin
  inherited;
  FLastClick := MinDateTime;
  FRenamable := true;
end;

procedure TTreeViewItem.ApplyStyle;
var
  LTextObj: TFmxObject;
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;

  LTextObj := FindTextObject();
  if LTextObj is TControl then
    FText := TControl(LTextObj);

  if not Assigned(FText) then
    Exit;

  //Don't forget to add the rename edit into custom style
  if FindStyleResource<TCustomEdit>('rename', FRename) then begin
    FRename.OnKeyUp := OnRenameKeyUp;
    FRename.OnChangeTracking := OnRenameChangeTracking;
    FRename.OnExit := OnRenameExit;
    UpdateRenameEditVisibility();
  end;
end;

procedure TTreeViewItem.FreeStyle;
begin
  inherited;
  if Assigned(FRename) then begin
    FRename.OnKeyUp := nil;
    FRename.OnChangeTracking := nil;
    FRename.OnExit := nil;
    FRename := nil;
    FText := nil;
  end;
end;

function TTreeViewItem.CanRename: boolean;
begin
  Result := FRenamable and Assigned(FRename);
end;

procedure TTreeViewItem.Click;
begin
  inherited;
  var LInterval := MilliSecondsBetween(FLastClick, Now);
  if (LInterval > 500) and (LInterval < 900) then begin
    if FLazyInput and CanRename() then
      DoStartRenaming();
  end else
    FLastClick := Now();
end;

procedure TTreeViewItem.DblClick;
begin
  inherited;
  if not FLazyInput and CanRename() then
    DoStartRenaming();
end;

procedure TTreeViewItem.DoStartRenaming;
begin
  FRenaming := true;
  FRename.Text := Self.Text;
  UpdateRenameEditVisibility();
  FRename.SetFocus();
end;

procedure TTreeViewItem.DoEndRenaming(const ACancel: boolean);
var
  LNewText: string;
begin
  if not FRenaming then
    Exit;

  //If we fail to rename, we cancel it...
  try
    if ACancel then
      Exit;

    LNewText := FRename.Text;
    if Assigned(FOnRename) then
      FOnRename(Self, Self.Text, LNewText);

    Self.Text := LNewText;
  finally
    FRenaming := false;
    UpdateRenameEditVisibility();
    Self.ResetFocus();
  end;
end;

procedure TTreeViewItem.UpdateRenameEditVisibility;
begin
  if not Assigned(FRename) or (csDesigning in ComponentState) then
    Exit;

  if Assigned(FText) then
    FText.Visible := not FRenaming;
  FRename.Visible := FRenaming;
end;

procedure TTreeViewItem.UpdateRenameEditSize;
begin
  FRename.Width := System.Math.Max(
    30,
    FRename.Canvas.TextWidth(FRename.Text) + 10);
end;

procedure TTreeViewItem.OnRenameKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
begin
  inherited;
  if Key in [vkReturn, vkEscape] then
    DoEndRenaming(Key = vkEscape);
end;

procedure TTreeViewItem.Rename;
begin
  if CanRename() then
    DoStartRenaming();
end;

procedure TTreeViewItem.OnRenameChangeTracking(Sender: TObject);
begin
  UpdateRenameEditSize();
end;

procedure TTreeViewItem.OnRenameExit(Sender: TObject);
begin
  DoEndRenaming(true);
end;

end.
