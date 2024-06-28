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
  iexPDFiumCore;

type
  TForm1 = class(TForm)
    ImageEnView1: TImageEnView;
    cxGrid1DBTableView1: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    Panel1: TPanel;
    Label1: TLabel;
    DataSource1: TDataSource;
    FClientDataSet1: TClientDataSet;

    procedure FormCreate(sender: TObject);
    procedure ReadXML();
    procedure MatchObject();
    procedure ImageEnView1ButtonClick(sender: TObject; button: TIEVButton;
        mouseButton: TMouseButton; shift: TShiftState; var handled: Boolean);
    procedure DrawBounds(objectIndex: Integer);
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

function FindObjWidth(obj: TPdfObject): Integer;
begin
  Result := obj.Bounds.Right - obj.Bounds.Left;
end;

function FindObjHeight(obj: TPdfObject): Integer;
begin
  Result := obj.Bounds.Bottom - obj.Bounds.Top;
end;

// ----Form Methods---- //

procedure TForm1.FormCreate(sender: TObject);
begin
  // Register the PDFium plug-in
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
  lXMLDoc: IXMLDocument;
  lRowNode: IXMLNode;
  lFieldName, lFieldValue: string;
begin
  lXMLDoc := LoadXMLDocument('sample-input\sample.xml');

  // Access the rootdata node
  lRowNode := lXMLDoc.DocumentElement.ChildNodes['ROWDATA'].ChildNodes['ROW'];

  // Initialise client dataset fields to extract the fields and values from XML
  FClientDataSet1.Close;
  FClientDataSet1.FieldDefs.Clear;
  FClientDataSet1.FieldDefs.Add('Fields', ftString, 30);
  FClientDataSet1.FieldDefs.Add('Value', ftString, 255);
  FClientDataSet1.CreateDataSet;

  // Extract the field attribute and the values
  for var i := 0 to lRowNode.AttributeNodes.Count - 1 do
  begin
    lFieldName := lRowNode.AttributeNodes[i].NodeName;
    lFieldValue := lRowNode.Attributes[lFieldName];

    FClientDataSet1.Append;
    FClientDataSet1.FieldByName('Fields').AsString := lFieldName;
    FClientDataSet1.FieldByName('Value').AsString := lFieldValue;
    FClientDataSet1.Post;
  end;
end;

procedure TForm1.MatchObject();
begin
  var
    lFound: Boolean := false;

  // Compare the lTxtObjectList with the clientdataset
  for var j := 1 to FClientDataSet1.RecordCount do
  begin
    // Set ClientDataSet current head index
    FClientDataSet1.RecNo := j;
    lFound := false;

    for var i := 0 to ImageEnView1.PdfViewer.Objects.Count - 1 do
    begin
      if lFound then Break;
      if ImageEnView1.PdfViewer.Objects[i].ObjectType = ptText then
      begin
        if ImageEnView1.PdfViewer.Objects[i].Text.Contains
          (FClientDataSet1.FieldByName('Value').AsString) then
        begin
          DrawBounds(i);
        end;
      end;
    end;
  end;
end;

// button Click event of our TImageEnView
procedure TForm1.ImageEnView1ButtonClick(sender: TObject; button: TIEVButton;
    mouseButton: TMouseButton; shift: TShiftState; var handled: Boolean);
begin
  case button of
    iebtPrevious:
      begin
        // If press shift then skip to first page
        if ssShift in shift then
          ImageEnView1.Seek(ieioSeekFirst)
        else
          ImageEnView1.Seek(ieioSeekPrior);
      end;
    iebtNext:
      begin
        // If press shift then skip to last page
        if ssShift in shift then
          ImageEnView1.Seek(ieioSeekLast)
        else
          ImageEnView1.Seek(ieioSeekNext);
      end;
  end;

  // Call this method to make sure the red bounds won't disappear
  MatchObject();
end;

procedure TForm1.DrawBounds(objectIndex: Integer);
const
  c_Rect_Color = clRed;
  c_Rect_Border = 1;
  c_Rect_Opacity = 0;
  c_Rect_Offset = 2; // To add some extra space in the bounds
var
  lObj: TPdfObject;

begin
  lObj := ImageEnView1.PdfViewer.Objects.AddRect
    (ImageEnView1.PdfViewer.Objects[objectIndex].X,
    ImageEnView1.PdfViewer.Objects[objectIndex].Y,
    FindObjWidth(ImageEnView1.PdfViewer.Objects[objectIndex]) + c_Rect_Offset,
    FindObjHeight(ImageEnView1.PdfViewer.Objects[objectIndex]) + c_Rect_Offset);

  lObj.StrokeColor := TColor2TRGBA(c_Rect_Color, 255);
  lObj.PathStrokeWidth := c_Rect_Border;
  lObj.FillColor := TColor2TRGBA(c_Rect_Opacity);
  lObj.PathFillMode := pfAlternate;

  ImageEnView1.Invalidate();
end;

end.
