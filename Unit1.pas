unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, hyiedefs, hyieutils, iexBitmaps,
  iesettings, iexLayers, iexRulers, iexToolbars, iexUserInteractions, imageenio,
  imageenproc, iexProcEffects, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  Data.DB, cxDBData, Vcl.ExtCtrls, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, ieview,
  imageenview, Vcl.StdCtrls, Datasnap.DBClient, Xml.XMLDoc, Xml.XMLIntf, iexPDFiumCore;

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
    procedure Main();
    procedure FormCreate(Sender: TObject);
    procedure OpenPDF();
    procedure ReadXML();
    procedure UpdateObjectList();
    procedure MatchObject();
    procedure ImageEnView1ButtonClick(Sender: TObject; Button: TIEVButton;
        MouseButton: TMouseButton; Shift: TShiftState; var Handled: Boolean);
  private
    { Private declarations }
    lTxtObjectList: TArray<String>;
    lHighlightIndex: Integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// ----Utility---- //

function PdfObjectTypeToStr(ObjType: TPdfObjectType): string;
begin
  case ObjType of
    ptText     : Result := 'Text';
    ptPath     : Result := 'Path';
    ptImage    : Result := 'Image';
    ptShading  : Result := 'Shading';
    ptForm     : Result := 'Form';
    else // ptUnknown
                 Result := 'Unknown';
  end;
end;

// ----Form Methods---- //

procedure TForm1.FormCreate(Sender: TObject);
begin
  // register the PDFium plug-in
  IEGlobalSettings.RegisterPlugIns( [ iepiIEVision, iepiPDFium ], '', '', false );

  // Display a PDF document (and allow text and image selection)
  ImageEnView1.PdfViewer.Enabled := true;
//  ImageEnView1.PdfViewer.ShowAllPages := True;
  ImageEnView1.MouseInteractGeneral := [ miPdfSelectText ];


  Main();
end;

procedure TForm1.Main();
begin
  OpenPDF();
  UpdateObjectList();
  ReadXML();
  MatchObject();
end;

procedure TForm1.OpenPDF();
begin
  ImageEnView1.IO.LoadFromFilePDF('C:\Users\0000\Downloads\sample-invoice.pdf');
end;

procedure TForm1.ReadXML();
var
  XMLDoc: IXMLDocument;
  RowNode: IXMLNode;
  FieldName, FieldValue: string;
begin
  XMLDoc := LoadXMLDocument('C:\Users\0000\Downloads\sample.xml');

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

procedure TForm1.UpdateObjectList();
var
  lObjType: TPDfObjectType;
  lObj, lTxt: String;
begin
  var lCount: Integer := -1;

  for var i := 0 to ImageEnView1.PdfViewer.Objects.Count - 1 do
    begin
      lObjType := ImageEnView1.PdfViewer.Objects[i].ObjectType;
      lObj := PdfObjectTypeToStr(lObjType);

      lTxt := '';
      if lObjType = ptText then
        begin
          lTxt := Trim( ImageEnView1.PdfViewer.Objects[i].Text );
        end;

      if lTxt <> '' then
        begin
          Inc(lCount);
          setLength(lTxtObjectList, lCount + 1);
          lTxtObjectList[lCount] := lTxt;
        end;
    end;
  if Length(lTxtObjectList) = 0 then
    ShowMessage('No PDF Object Found.');

end;

procedure TForm1.MatchObject();
begin
  var lFound: boolean := False;
  
  // compare the lTxtObjectList with the clientdataset
  for var j := 1 to ClientDataSet1.RecordCount do
  begin
    ClientDataSet1.RecNo := j;
    lFound := False;
    
    for var i := 0 to ImageEnView1.PdfViewer.Objects.Count - 1 do
    begin
      if lFound then Break;
      if ImageEnView1.PdfViewer.Objects[i].ObjectType = ptText then
        begin
          if ImageEnView1.PdfViewer.Objects[i].Text.Contains(ClientDataSet1.FieldByName('Value').AsString) then
          begin
            lFound := True;
            lHighlightIndex := i;
            ImageEnView1.HighlightColor := clRed;
            ImageEnView1.PdfViewer.Objects.HighlightedIndex := i;
            ImageEnView1.Invalidate();         
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
    iebtPrevious : begin
                     if ssShift in Shift then
                       ImageEnView1.Seek( ieioSeekFirst )
                     else
                       ImageEnView1.Seek( ieioSeekPrior );
                   end;
    iebtNext     : begin
                     if ssShift in Shift then
                       ImageEnView1.Seek( ieioSeekLast )
                     else
                       ImageEnView1.Seek( ieioSeekNext );
                   end;
  end;
  MatchObject();
end;

end.
