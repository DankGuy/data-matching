object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Matching Data'
  ClientHeight = 622
  ClientWidth = 1046
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  TextHeight = 15
  object ImageEnView1: TImageEnView
    Left = 0
    Top = 8
    Width = 625
    Height = 569
    TabOrder = 0
    AutoStretch = True
    AutoShrink = True
    OnButtonClick = ImageEnView1ButtonClick
  end
  object cxGrid1: TcxGrid
    Left = 624
    Top = 8
    Width = 414
    Height = 569
    TabOrder = 1
    object cxGrid1DBTableView1: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.DataSource = DataSource1
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsCustomize.ColumnFiltering = False
      OptionsCustomize.ColumnGrouping = False
      OptionsView.GroupByBox = False
      object Fields: TcxGridDBColumn
        DataBinding.FieldName = 'Fields'
        DataBinding.IsNullValueType = True
      end
      object Value: TcxGridDBColumn
        DataBinding.FieldName = 'Value'
        DataBinding.IsNullValueType = True
      end
    end
    object cxGrid1Level1: TcxGridLevel
      GridView = cxGrid1DBTableView1
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 576
    Width = 1038
    Height = 48
    TabOrder = 2
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 752
      Height = 21
      Caption = 
        'This page suggests that the field stated may have mistakes, you ' +
        'are suggested to check the field values again.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object DataSource1: TDataSource
    DataSet = ClientDataSet1
    Left = 656
    Top = 72
  end
  object ClientDataSet1: TClientDataSet
    PersistDataPacket.Data = {
      800000009619E0BD0100000018000000030001000000030000005A000354494E
      01004A0010000100055749445448020002000F00044E414D4501004A00100001
      0005574944544802000200640006414D4F554E54080004001000000000000000
      0E30003100320033003400350036000C4B0065006C00760069006E000AD7A370
      3D4A9340}
    Active = True
    Aggregates = <>
    Params = <>
    Left = 728
    Top = 72
  end
end
