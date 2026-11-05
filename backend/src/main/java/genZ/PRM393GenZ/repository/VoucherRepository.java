package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Voucher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface VoucherRepository extends JpaRepository<Voucher, Integer> {
    Optional<Voucher> findByCode(String code);

    // Voucher còn hạn (ExpiryDate > thời điểm truyền vào)
    List<Voucher> findByExpiryDateAfter(LocalDateTime time);
}
