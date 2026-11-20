# AquaCare – Clean Water and Sanitation (UN SDG 6)

**AquaCare** là ứng dụng theo dõi cấp ẩm hằng ngày, giám sát chất lượng nước sinh hoạt (chuẩn WHO / QCVN 01-1:2018/BYT), thúc đẩy thói quen vệ sinh cá nhân & gia đình (WASH) và kết nối bản đồ trạm tiếp nước sạch / điểm rửa tay công cộng theo Mục tiêu Phát triển Bền vững Liên Hợp Quốc số 6 (**SDG 6: Clean Water and Sanitation**).

## 3 Chế độ sử dụng thích ứng (Role-Adaptive)

1. **Sinh viên & Người đi làm (`SV / Đi làm`)**
   - Biểu tượng linh vật chứa sóng nước đa sắc tương tác (Waterllama-inspired), kéo cốc khổng lồ chọn đồ uống & thể tích.
   - **Sống xanh & vệ sinh**: thống kê 7 ngày, quy đổi chai nhựa dùng 1 lần & CO₂ tiết kiệm được, checklist rửa bình cá nhân & rửa tay 6 bước (WASH), bù nước theo Caffeine / thời tiết / vận động, nhắc uống nước theo ca 25 phút.
   - Quét mã vạch chai nước & mã QR trạm Refill với nhắc nhở sống xanh SDG 6.
2. **Hộ gia đình (`Hộ gia đình`)**
   - **Nước sạch & vệ sinh**: đánh giá chỉ số TDS / pH / Clo dư / Độ đục phân tách theo loại nguồn nước (`Lọc RO < 50 ppm`, `Nước máy / Đun sôi ≤ 300 ppm`, `Nước khoáng ≤ 300 ppm`) kèm biểu đồ biến động động theo lịch sử đo.
   - Checklist vệ sinh nước sạch (WASH) gia đình, theo dõi bảo trì bộ lọc nước & phát hiện rò rỉ đường ống qua chỉ số đồng hồ nước tháng.
3. **Trẻ em (`Bé AquaKids`)**
   - Không gian khóa riêng toàn màn hình bảo vệ bằng Cổng Phụ huynh (PIN 4 số).
   - Bộ đếm khóa vòi đánh răng 2 phút tiết kiệm nước, 6 bước rửa tay với xà phòng, đố vui SDG 6 & sưu tập phụ kiện linh vật.

## Tính năng dùng chung

- **Bản đồ Trạm Refill & Vệ sinh công cộng**: Tích hợp OpenStreetMap (`flutter_map`) & bản đồ vector, lọc trạm miễn phí, nóng/lạnh, 24/7, điểm có **rửa tay & vệ sinh sạch**, đề xuất trạm mới và báo cáo sự cố nước/vệ sinh cộng đồng.
- **Trợ lý AI AquaBot**: Hỗ trợ phân tích chỉ số nước sạch, cấp ẩm và vệ sinh theo ngữ cảnh vai trò; hoạt động an toàn ở chế độ nội bộ trên thiết bị hoặc kết nối API ngoài qua `--dart-define`.

## Cấu hình & Chạy kiểm thử

### Kiểm tra mã nguồn & Unit/Widget Tests

```bash
flutter analyze
flutter test
```

### Chạy ứng dụng kèm cấu hình AI tùy chọn (`--dart-define`)

Không lưu API key trực tiếp trong mã nguồn. Khi cần kết nối máy chủ AI chuẩn Anthropic (`/v1/messages`) hoặc OpenAI (`/v1/chat/completions`), truyền biến qua lúc build/run hoặc cấu hình trực tiếp trong giao diện cài đặt AI của ứng dụng:

```bash
flutter run \
  --dart-define=AQUABOT_API_URL=https://your-gateway.example.com/v1/messages \
  --dart-define=AQUABOT_MODEL=your-model-name \
  --dart-define=AQUABOT_API_KEY=your-secret-api-key
```
