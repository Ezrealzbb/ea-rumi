//+------------------------------------------------------------------+
//|                                                         rumi.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//--- 引入指数平均线
#include <MovingAverages.mqh>



#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 100
#property indicator_plots   100
//--- plot RUMI
#property indicator_label1  "RUMI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_applied_price PRICE_CLOSE
#property indicator_width1  1
//--- input parameters
input int      fastMa=3;
input int      slowWMa=100;
input int      oMa=30;
//--- indicator buffers
double         RUMIBuffer[];
double         RUMIFastMaBuffer[];
double         RUMISlowWMaBuffer[];
double         RUMIOutBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   PrintFormat("%s: rumi init", "start");
   SetIndexBuffer(0, RUMIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1, RUMIFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, RUMISlowWMaBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, RUMIOutBuffer, INDICATOR_CALCULATIONS);
   
   // 设置绘图的一些属性
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, fastMa); // 从多少的柱形图开始
   string shortname;
   StringConcatenate(shortname, "RUMI(f:", fastMa, ",s:", slowWMa, ",o:", oMa, ")"); // 设置左上角的图表标签提示
   PlotIndexSetString(0, PLOT_LABEL, shortname);

//--- 设置指标的水平 0 值
   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0);
   //IndicatorSetInteger(INDICATOR_DIGITS, 6);
   //ArrayResize(RUMIBuffer, 10000, 10000);
   //ArrayResize(RUMIFastMaBuffer, 10000, 10000);
   //ArrayResize(RUMISlowWMaBuffer, 10000, 10000);
   //ArrayResize(RUMIOutBuffer, 10000, 10000);
   
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // price[]数组大小;
                 const int prev_calculated,  // 上次调用计算后的价格柱的数量
                 const int begin,            // price[]数组开始计算的索引
                 const double& price[])      // 指标计算的依据数组, 
  {
  PrintFormat("%s: log value rate_total: %d, prev_calculated: %d, begin: %d", __FUNCTION__, rates_total, prev_calculated, begin);
//--- rates_total 是 price.length
//--- price[] 中的元素索引从零开始，方向从过去至未来，即 price[0] 元素包含最旧的值，而 price[rates_total-1] 包含最新的数组值。
   if (rates_total < slowWMa) return (0);

   //--- 计算快周期的 普通加权平均，计算之后的结果在 RUMIFastMaBuffer 的结果数组中是从 fastMa 的索引位置开始的
   SimpleMAOnBuffer(rates_total, prev_calculated, begin, fastMa, price, RUMIFastMaBuffer);
   // 计算慢周期的 线性加权平均，计算之后的结果在 RUMISlowWMaBuffer 的结果中是从 slowWma 的索引位置开始
   LinearWeightedMAOnBuffer(rates_total, prev_calculated, begin, slowWMa, price, RUMISlowWMaBuffer);
   //--- 计算二者的差值，注意在fastMa 中是：[0,0,x,x,x,x,x]，在 slowWMa中是[0,0,0,0,0,0,0,0,x,x,x,x,x]
   //--- 做差计算，起始点是 prev_calculated - 1，相当于说只计算新出现的数据，原来的数据已经计算好在缓冲区内了
   
   for (int i = prev_calculated; i < rates_total; i++) {
      RUMIOutBuffer[i] = RUMIFastMaBuffer[i] - RUMISlowWMaBuffer[i];
   }
   // 对差值再做一次 ma 运算，由于 RUMISlowWMaBuffer 至少要从 slowWMa - 1 处才开始有数据，这里的begin我们取 slowWMa
   SimpleMAOnBuffer(rates_total, prev_calculated, slowWMa, oMa, RUMIOutBuffer, RUMIBuffer);
   
//--- 返回值会作为下一次调用的 prev_calculated 参数调用
   return(rates_total);
  } 
//+------------------------------------------------------------------+
