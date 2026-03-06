/******************************************************************************
* Copyright (C) 2018 - 2022 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
*******************************************************************************/

/*****************************************************************************/
/**
*
* @file sensor_config_pcam.h
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- --------------------------------------------------
* X.XX  XX     YY/MM/DD
* 1.00  RHe    19/09/20 Initial release.
* </pre>
*
******************************************************************************/
#ifndef SENSOR_CONFIG_PCAM_H
#define SENSOR_CONFIG_PCAM_H

extern struct regval_list {
  u16 Address;
  u16  Data;
} regval_list;

extern struct regval_list sensor_cfg[];
extern const int length_sensor_cfg;

extern struct regval_list sensor_list[];
extern const int length_sensor_list;

#endif
