unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, hyiedefs, hyieutils, iexBitmaps,
  iesettings, iexLayers, iexRulers, iexToolbars, iexUserInteractions, imageenio,
  imageenproc, iexProcEffects, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  Data.DB, cxDBData, Vcl.ExtCtrls, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, ieview,
  imageenview, Vcl.StdCtrls, Datasnap.DBClient, Xml.XMLDoc, Xml.XMLIntf,
  iexPDFiumCore,
  System.Generics.Collections;

type
  TForm1 = class(TForm)
    ImageEnView1: TImageEnView;
    cxGrid1DBTableView1: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    Panel1: TPanel;
    Label1: TLabel;
    DataSource1: TDataSource;
    ClientDataSet1: TClientDataSet;
    Fields: TcxGridDBColumn;
    Value: TcxGridDBColumn;

    procedure FormCreate(Sender: TObject);
    procedure ReadXML();
    procedure MatchObject();
    procedure ImageEnView1ButtonClick(Sender: TObject; Button: TIEVButton;
      MouseButton: TMouseButton; Shift: TShiftState; var Handled: Boolean);
    procedure DrawBounds(ObjectIndex: Integer);
  private
    { Private declarations }
  public
    { Public declarations }

  end;

var
  Form1: TForm1;

function FindObjWidth(Obj: TPdfObject): Integer;
function FindObjHeight(Obj: TPdfObject): Integer;

implementation

{$R *.dfm}
// ----Utility---- //

function FindObjWidth(Obj: TPdfObject): Integer;
begin
  Result := Obj.Bounds.Right - Obj.Bounds.Left;
end;

function FindObjHeight(Obj: TPdfObject): Integer;
begin
  Result := Obj.Bounds.Bottom - Obj.Bounds.Top;
end;

// ----Form Methods---- //

procedure TForm1.FormCreate(Sender: TObject);
begin
  // register the PDFium plug-in
  IEGlobalSettings.RegisterPlugIns([iepiIEVision, iepiPDFium], '', '', false);

  // Display a PDF document (and allow text and image selection)
  ImageEnView1.PdfViewer.Enabled := true;
  ImageEnView1.MouseInteractGeneral := [miPdfSelectText];

  ImageEnView1.IO.LoadFromFilePDF('sample-input\sample-invoice.pdf');
  ReadXML();
  MatchObject();

end;

procedure TForm1.ReadXML();
var
  XMLDoc: IXMLDocument;
  RowNode: IXMLNode;
  FieldName, FieldValue: string;
begin
  XMLDoc := LoadXMLDocument('sample-input\sample.xml');

  // access the rootdata node
  RowNode := XMLDoc.DocumentElement.ChildNodes['ROWDATA'].ChildNodes['ROW'];

  // initialise client dataset fields to extract the fields and values from XML
  ClientDataSet1.Close;
  ClientDataSet1.FieldDefs.Clear;
  ClientDataSet1.FieldDefs.Add('Fields', ftString, 30);
  ClientDataSet1.FieldDefs.Add('Value', ftString, 255);
  ClientDataSet1.CreateDataSet;

  // Extract the field attribute and the values
  for var i := 0 to RowNode.AttributeNodes.Count - 1 do
  begin
    FieldName := RowNode.AttributeNodes[i].NodeName;
    FieldValue := RowNode.Attributes[FieldName];

    ClientDataSet1.Append;
    ClientDataSet1.FieldByName('Fields').AsString := FieldName;
    ClientDataSet1.FieldByName('Value').AsString := FieldValue;
    ClientDataSet1.Post;
  end;
end;

procedure TForm1.MatchObject();
begin
  var
    lFound: Boolean := false;

  // compare the lTxtObjectList with the clientdataset
  for var j := 1 to ClientDataSet1.RecordCount do
  begin
    ClientDataSet1.RecNo := j;
    lFound := false;

    for var i := 0 to ImageEnView1.PdfViewer.Objects.Count - 1 do
    begin
      if lFound then
        Break;
      if ImageEnView1.PdfViewer.Objects[i].ObjectType = ptText then
      begin
        if ImageEnView1.PdfViewer.Objects[i].Text.Contains
          (ClientDataSet1.FieldByName('Value').AsString) then
        begin
          DrawBounds(i);
        end;
      end;
    end;
  end;
end;

// Button Click event of our TImageEnView
procedure TForm1.ImageEnView1ButtonClick(Sender: TObject; Button: TIEVButton;
  MouseButton: TMouseButton; Shift: TShiftState; var Handled: Boolean);
begin
  case Button of
    iebtPrevious:
      begin
        if ssShift in Shift then
          ImageEnView1.Seek(ieioSeekFirst)
        else
          ImageEnView1.Seek(ieioSeekPrior);
      end;
    iebtNext:
      begin
        if ssShift in Shift then
          ImageEnView1.Seek(ieioSeekLast)
        else
          ImageEnView1.Seek(ieioSeekNext);
      end;
  end;

  // call this method to make sure the red bounds won't disappear
  MatchObject();
end;

procedure TForm1.DrawBounds(ObjectIndex: Integer);
const
  Rect_Color = clRed;
  Rect_Border = 1;
  Rect_Opacity = 0;
  Rect_Offset = 2;
var
  Obj: TPdfObject;

begin
  Obj := ImageEnView1.PdfViewer.Objects.AddRect
    (ImageEnView1.PdfViewer.Objects[ObjectIndex].X,
    ImageEnView1.PdfViewer.Objects[ObjectIndex].Y,
    FindObjWidth(ImageEnView1.PdfViewer.Objects[ObjectIndex]) + Rect_Offset,
    FindObjHeight(ImageEnView1.PdfViewer.Objects[ObjectIndex]) + Rect_Offset);

  Obj.StrokeColor := TColor2TRGBA(Rect_Color, 255);
  Obj.PathStrokeWidth := Rect_Border;
  Obj.FillColor := TColor2TRGBA(Rect_Opacity);
  Obj.PathFillMode := pfAlternate;

  ImageEnView1.Invalidate();
end;

end.
