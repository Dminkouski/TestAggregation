DATA:
  lr_output_data        TYPE REF TO data,
  lv_message            TYPE string,
  lv_linitial_directory TYPE string,
  lv_default_file_name  TYPE string,
  ls_layout             TYPE lvc_s_layo,
  lt_fieldcat           TYPE lvc_t_fcat.
FIELD-SYMBOLS: <tab> TYPE STANDARD TABLE.

CLEAR :
  lv_message,
  lv_linitial_directory,
  lv_default_file_name.

SELECT /scmtms/d_torrot~tor_id, /scmtms/d_torite~item_id, parent_key, /scmtms/d_torite~gro_wei_val, /scmtms/d_torite~gro_wei_uni
  FROM /scmtms/d_torite
  INNER JOIN /scmtms/d_torrot ON /scmtms/d_torrot~db_key = /scmtms/d_torite~parent_key
  INTO TABLE @DATA(lt_output_data)
  WHERE tor_id = '00000000004100177396' OR
        tor_id = '00000000004100177397' OR
        tor_id = '00000000004100177398' OR
        tor_id = '00000000004100177399' OR
        tor_id = '00000000004100177600' .

GET REFERENCE OF lt_output_data INTO lr_output_data.
ASSIGN lr_output_data->* TO <tab>.

cl_salv_table=>factory(
  EXPORTING
    list_display = abap_false
  IMPORTING
    r_salv_table = DATA(lo_salv_table)
  CHANGING
    t_table      = <tab> ).

DATA(lo_aggr) = lo_salv_table->get_aggregations( ).
DATA(lo_groupping) = lo_salv_table->get_sorts( ).

lo_groupping->add_sort(
  EXPORTING
    columnname =  CONV #( /scmtms/if_tor_c=>sc_node_attribute-root-tor_id )
    subtotal   =  abap_true
    group      =  if_salv_c_sort=>group_with_underline ).
lo_aggr->add_aggregation(
  EXPORTING
    columnname  = CONV #( /scmtms/if_tor_c=>sc_node_attribute-item_tr-gro_wei_val )
    aggregation = if_salv_c_aggregation=>total ).

DATA(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
                         r_columns      = lo_salv_table->get_columns( )
                         r_aggregations = lo_aggr ).
DATA(lt_sort) = cl_salv_controller_metadata=>get_lvc_sort( lo_groupping  ).

DATA(lt_result_data_table) = cl_salv_ex_util=>factory_result_data_table(
  EXPORTING
    r_data              = lr_output_data
    s_layout            = ls_layout
    t_fieldcatalog      = lt_fcat
    t_sort              = lt_sort ).

cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
  EXPORTING
    xml_version   = if_salv_bs_xml=>version
    r_result_data = lt_result_data_table
    xml_type      = 10
    xml_flavour   = if_salv_bs_c_tt=>c_tt_xml_flavour_export
    gui_type      = if_salv_bs_xml=>c_gui_type_gui
  IMPORTING
    xml           = DATA(lv_xml)
    t_msg         = DATA(lt_msg) ).

READ TABLE lt_msg ASSIGNING FIELD-SYMBOL(<fs_msg>) WITH KEY msgty = 'E'.
IF sy-subrc = 0.
  CALL FUNCTION 'SX_MESSAGE_TEXT_BUILD'
    EXPORTING
      msgid               = <fs_msg>-msgid
      msgnr               = <fs_msg>-msgno
      msgv1               = <fs_msg>-msgv1
      msgv2               = <fs_msg>-msgv2
      msgv3               = <fs_msg>-msgv3
      msgv4               = <fs_msg>-msgv4
    IMPORTING
      message_text_output = lv_message.

  MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'I'.
  RETURN.
ENDIF.

CALL FUNCTION 'XML_EXPORT_DIALOG'
  EXPORTING
    i_xml                      = lv_xml
    i_default_extension        = 'XLSX'
    i_initial_directory        = lv_linitial_directory
    i_default_file_name        = lv_default_file_name
    i_mask                     = 'Excel (*.XLSX)|*.XLSX'
  EXCEPTIONS
    application_not_executable = 1
    OTHERS                     = 2.

IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.