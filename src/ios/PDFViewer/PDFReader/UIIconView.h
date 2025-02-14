//
//  UIIconView.h
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/13.
//  Copyright © 2020 Radaee. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "UILShadowView.h"
typedef void(^func_icon)(int);
@class PDFPopupCtrl;
@class RDPDFAnnot;
@class RDPDFDIB;
@interface UIIconBtn : UIImageView
{
    int m_atype;
    int m_icon;
    UIViewController *m_vc;
    RDPDFDIB *m_dib;
    PDFPopupCtrl *m_popup;
    NSMutableArray *m_dibs;
    UIScrollView *m_view;
}
-(id)initWithCoder:(NSCoder *)aDecoder;
-(id)initWithFrame:(CGRect)frame;
-(void)setIcon:(RDPDFAnnot *)annot :(UIViewController *)vc;
-(int)icon;
@end
