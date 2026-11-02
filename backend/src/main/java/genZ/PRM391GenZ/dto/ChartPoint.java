package genZ.PRM391GenZ.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

// 1 cột trong biểu đồ doanh thu, VD: label "01/11", revenue 276000
@Data
@AllArgsConstructor
public class ChartPoint {
    private String label;
    private BigDecimal revenue;
}
