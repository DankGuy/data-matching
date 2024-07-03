unit Unit1;

interface

uses
  System.SysUtils,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, hyieutils,
  iesettings, iexUserInteractions, imageenio,
  Data.DB, Vcl.ExtCtrls, cxGridLevel, cxGridCustomView,
  cxGridDBTableView, cxGrid, ieview,
  imageenview, Vcl.StdCtrls, Datasnap.DBClient, Xml.XMLDoc, Xml.XMLIntf,
  iexPDFiumCore, hyiedefs, iexBitmaps, iexLayers, iexRulers, iexToolbars,
  imageenproc, iexProcEffects, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  cxDBData, cxGridCustomTableView, cxGridTableView, cxClasses, ieopensavedlg,
  Vcl.Menus, cxButtons, StrUtils, Vcl.Dialogs;

type
  TForm1 = class(TForm)
    ImageEnView1: TImageEnView;
    gv: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    pn: TPanel;
    lb: TLabel;
    ds: TDataSource;
    cds: TClientDataSet;
    SaveImageEnDialog: TSaveImageEnDialog;
    saveBtn: TcxButton;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(sender: TObject);
    procedure ReadXML();
    procedure MatchObject();
    procedure ImageEnView1ButtonClick(sender: TObject; button: TIEVButton;
      mouseButton: TMouseButton; shift: TShiftState; var handled: Boolean);
    procedure DrawBounds(objectIndex: Integer);
    procedure saveBtnClick(sender: TObject);
    procedure SaveChanges();

  private
    lInvoicePath: String;
    lXMLPath: String;
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

procedure TForm1.FormCreate(sender: TObject);
begin
  // Register the PDFium plug-in
  IEGlobalSettings.RegisterPlugIns([iepiIEVision, iepiPDFium], '', '', false);

  // Display a PDF document (and allow text and image selection)
  ImageEnView1.PdfViewer.Enabled := true;
  ImageEnView1.MouseInteractGeneral := [miPdfSelectText];

  // Initialize Document Path
  lInvoicePath := 'sample-input\sample-invoice.pdf';
  lXMLPath := 'sample-input\sample.xml';

  ImageEnView1.IO.LoadFromFilePDF(lInvoicePath);
  ReadXML();
  MatchObject();
end;

procedure TForm1.ReadXML();
var
  lXMLDoc: IXMLDocument;
  lRowNode: IXMLNode;
  lFieldName, lFieldValue: string;
begin
  lXMLDoc := LoadXMLDocument(lXMLPath);

  // Access the rootdata node
  lRowNode := lXMLDoc.DocumentElement.ChildNodes['ROWDATA'].ChildNodes['ROW'];

  // Initialise client dataset fields to extract the fields and values from XML
  cds.Close;
  cds.FieldDefs.Clear;
  cds.FieldDefs.Add('Fields', ftString, 30);
  cds.FieldDefs.Add('Value', ftString, 255);
  cds.CreateDataSet;

  // Extract the field attribute and the values
  for var i := 0 to lRowNode.AttributeNodes.Count - 1 do begin
    lFieldName := lRowNode.AttributeNodes[i].NodeName;
    lFieldValue := lRowNode.Attributes[lFieldName];

    cds.Append;
    cds.FindField('Fields').AsString := lFieldName;
    cds.FindField('Value').AsString := lFieldValue;
    cds.Post;
  end;
end;

procedure TForm1.saveBtnClick(sender: TObject);
var
  lFileNameArr: TArray<String>;
  lFileName: String;
begin
  lFileNameArr := SplitString(lInvoicePath, '\');
  lFileName := lFileNameArr[Length(lFileNameArr) - 1];
  // remove file extension from file name and add custom filename
  SaveDialog1.DefaultExt := '.pdf';
  // Ensure the filter includes PDF files
  SaveDialog1.Filter := 'PDF Files (*.pdf)|*.pdf|All Files (*.*)|*.*';
  SaveDialog1.FileName := lFileName + '-matched';

  if SaveDialog1.Execute() then
  begin
    SaveChanges();
    // Save the annotated PDF
    ImageEnView1.IO.SaveToFilePDF(SaveDialog1.FileName);
  end;
end;

procedure TForm1.MatchObject();
begin
  // Compare the lTxtObjectList with the clientdataset
  for var j := 1 to cds.RecordCount do begin
    // Set ClientDataSet current head index
    cds.RecNo := j;

    for var i := 0 to ImageEnView1.PdfViewer.Objects.Count - 1 do begin
      if ImageEnView1.PdfViewer.Objects[i].ObjectType = ptText then
      begin
        if ImageEnView1.PdfViewer.Objects[i].Text.Contains
          (cds.FindField('Value').AsString) then
        begin
          DrawBounds(i);
        end;
      end;
    end;
  end;
end;

// Button Click event of our TImageEnView
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

procedure TForm1.SaveChanges();
begin
  for var i := 0 to ImageEnView1.PdfViewer.PageCount do begin
    MatchObject();
    ImageEnView1.PdfViewer.CurrentPage.ApplyChanges;
    ImageEnView1.PdfViewer.PageIndex := ImageEnView1.PdfViewer.PageIndex + 1;
  end;
end;

end.
