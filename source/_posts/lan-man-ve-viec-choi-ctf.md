---
title: Những suy nghĩ của một học sinh cấp 3 chơi CTF trong thời đại AI đang thống trị (dịch)
date: 2026-09-10 00:40:00
tags: [AI, Thought]
categories:
  - AI Slop
---

Bài này tôi dịch từ 1 người trong đội thi giành được top 1 trong giải ASIS Quals CTF 2026. Một giải CTF tôi chơi lại trong thời gian gần đây, tuy nhiên sau khi chơi xong vài giải thì tôi quyết định không chơi CTF nữa. Có lẽ cũng nhiều người không chơi CTF nữa vì lý do không còn tìm được niềm vui khi tham gia CTF. 
Đúng vậy, CTF không còn vui như ngày xưa nữa, việc giải được bài quá nhanh, không trải qua cảm giác hard stuck làm ta không thấy được niềm vui khi giải được một bài khó, trải nghiệm cảm giác dopamine hit. Đồng thời vào thời đại ai cũng dùng AI, tôi cảm thấy mọi người ít viết write up hơn hẳn, gần đây tôi có chơi lại một vài giải thì cảm thấy quá ít người write up lại. Tôi cảm thấy tiếc cho những ngày tháng trong quá khứ, nơi người chơi CTF vẫn hưởng được niềm vui trọn vẹn. 
Okay, đó là vài dòng suy nghĩ lan man của tôi. Còn với suy nghĩ của 1 người sinh sau đẻ muộn, họ có trải nghiệm gì, suy nghĩ gì khi tham gia CTF trong cái thời đại AI đang quá mạnh như thế này. Liệu họ có thấy được niềm vui khi chơi CTF giống tôi vài năm về trước không ?

# Những suy nghĩ của một học sinh cấp 3 chơi CTF trong thời đại AI đang thống trị
Author: 👤 **comet**
Date: 📅 **28/07/2026**

## Trước khi bắt đầu
Tôi bắt đầu học **Pwnable** từ cuối năm 2024 và từ năm 2025 bắt đầu nghiêm túc tham gia nhiều giải CTF. Hiện tại tôi vẫn đang là học sinh lớp 10 và vẫn tiếp tục chơi CTF.
Đây không phải là một bài viết với mục đích to tát như phân tích tương lai của ngành bảo mật. Tôi cũng không phải chuyên gia bảo mật có kinh nghiệm thực tế, và phần lớn kinh nghiệm mà tôi tích lũy được cho đến nay đều đến từ CTF.
Vì vậy, hãy xem bài viết này đơn giản là những cảm nhận gần đây của một học sinh cấp 3 bắt đầu chơi CTF đúng vào thời điểm AI đang phát triển cực kỳ nhanh.
Ngoài ra, bài viết này cũng **không nhằm nói rằng chúng ta không nên sử dụng AI trong CTF**.
Bản thân tôi cũng sử dụng AI cực kỳ tích cực trong các cuộc thi. Thậm chí chính vì tôi sử dụng nó quá nhiều nên tôi mới bắt đầu có những suy nghĩ như thế này.

# Cú “vỡ mộng” lớn nhất của tôi với CTF: CODEGATE 2026 Quals
Tháng 3 năm nay, tôi tham gia **CODEGATE 2026 Quals Junior**, đạt thứ hạng đủ để lọt vào vòng chung kết và thực tế cũng đã đến thi tại địa điểm tổ chức vòng chung kết.
Nếu chỉ nhìn vào kết quả thì đáng lẽ tôi phải rất vui. Trong lúc thi, mỗi khi giải được bài và thứ hạng tăng lên, tất nhiên tôi cũng rất vui. Nhưng sau khi cuộc thi kết thúc, thứ còn lại trong tôi lại là **cảm giác trống rỗng nhiều hơn cảm giác thành tựu**.

Khi nhìn lại những gì mình đã làm trong suốt cuộc thi, tôi nhận ra gần như công việc của mình chỉ là điền vào năm dòng sau:

**Tên bài:**
**Mô tả bài:**
**Thông tin kết nối:**
**Định dạng flag:**
**File đính kèm:**

Tôi đưa những thông tin đó vào một prompt dành cho Codex mà mình đã chuẩn bị từ trước, sau đó upload file. Giải xong một bài, tôi lại làm y hệt với bài tiếp theo.
Codex tự mở file, chạy các công cụ phân tích, viết code, nếu thất bại thì tự sửa, cuối cùng thậm chí tự kết nối tới server từ xa và lấy flag.

Việc của tôi chủ yếu là bổ sung thêm thông tin ở giữa quá trình rồi lấy flag mà nó tìm được để submit. Gần như toàn bộ những bài tôi giải được trong cuộc thi đều diễn ra theo cách đó.

Trong lúc thi, tôi chỉ nhìn thấy flag xuất hiện và cảm thấy vui. Nhưng khi cuộc thi kết thúc, một câu hỏi cứ quanh quẩn trong đầu tôi:
> **Vậy rốt cuộc ai mới là người giải bài này?**

Flag được submit bằng tài khoản của tôi và điểm được tính cho đội của tôi, vì vậy trên bảng thành tích thì đúng là tôi đã giải bài đó.

Nhưng nếu ai đó hỏi tôi:
* Ý tưởng cốt lõi của bài là gì?
* Tại sao lỗ hổng đó lại tồn tại?
* Exploit hoạt động theo nguyên lý nào?
thì với khá nhiều bài, tôi sẽ rất khó trả lời một cách tử tế.
Trong tình trạng như vậy, liệu tôi có thực sự có thể nói rằng **“tôi đã giải bài này”** hay không thì tôi cũng không chắc. Nó chắc chắn rất khác so với CTF mà tôi từng chơi trước đây.

# Thời đại không biết Pwnable vẫn giải được Pwnable

Lĩnh vực chính mà tôi học là **Pwnable**. Ban đầu, tôi thậm chí còn không biết kết quả của `checksec` có ý nghĩa gì. Có những lúc chương trình crash mà tôi không hiểu tại sao, nên mở GDB lên rồi chỉ ngồi nhìn màn hình register và stack rất lâu.

Để giải được một bài, tôi phải học từng thứ một tùy theo vấn đề mình gặp phải:
* cấu trúc ELF,
* các cơ chế bảo vệ bộ nhớ,
* assembly,
* cấu trúc glibc,
* v.v.

Nhưng trong vòng loại CODEGATE, tôi đã thấy những thí sinh không chuyên Pwnable, thậm chí gần như chưa từng học Pwnable, vẫn có thể sử dụng AI để giải các bài Pwnable. Tôi hoàn toàn không có ý coi thường thành tích của họ.
Bản thân tôi cũng sử dụng AI theo đúng cách đó, và tôi cho rằng trong một cuộc thi, tận dụng tối đa những công cụ được phép sử dụng là một chiến thuật hoàn toàn bình thường.
Tuy nhiên, với tư cách một người đã dành rất nhiều thời gian vật lộn khi học Pwnable, thú thật là tôi cảm thấy hơi hụt hẫng. Trước đây, muốn giải một bài thuộc một lĩnh vực cụ thể thì ít nhất bạn phải có kiến thức nền tảng về lĩnh vực đó.

Bây giờ, ngay cả khi gần như không biết gì về lĩnh vực đó, bạn vẫn có thể đưa file cho AI agent, chạy đoạn code nó tạo ra và trong một số trường hợp flag sẽ xuất hiện. Điều đó không có nghĩa là chuyên môn đã trở nên vô dụng.

Nhưng **thời điểm mà chuyên môn thực sự trở nên cần thiết đã bị đẩy lùi về phía sau rất nhiều so với trước đây**. Với những bài dễ hoặc trung bình, AI có thể giúp người thiếu kiến thức vượt qua phần lớn chặng đường. Chỉ khi đến những điểm thực sự khó thì năng lực của con người mới bắt đầu thể hiện rõ.

# Mối quan hệ giữa flag và việc học hacking

Một trong những lý do lớn nhất khiến tôi thích CTF là vì **ham muốn lấy được flag tự nhiên dẫn đến việc học**.

Muốn giải bài nhưng không biết gì?
=> Thì phải học.

Học xong, dùng kiến thức đó để giải bài.
Gặp bài khó hơn lại bị mắc.
Lại phải học thứ mới.
Cứ lặp lại như vậy thì năng lực dần dần tăng lên.
Bản thân tôi ban đầu cũng không phải vì quá yêu thích Pwnable nên mới học nó. Tôi chỉ cảm thấy rất vui khi flag xuất hiện.

Tôi muốn cảm nhận cảm giác đó lần nữa nên tiếp tục mở bài tiếp theo. Nhưng để lấy được flag, tôi phải hiểu lỗ hổng, phải biết sử dụng debugger và phải hiểu bộ nhớ hoạt động như thế nào.

Đối với tôi, **flag giống như một miếng mồi khiến tôi tiếp tục học**.

Nhưng bây giờ AI cho phép chúng ta bỏ qua phần khó khăn nhất ở giữa. Bạn có thể lấy flag mà không hiểu hoàn toàn bài toán. Bạn có thể không hiểu nguyên lý của lỗ hổng nhưng agent vẫn viết exploit cho bạn. Nếu code thất bại, chỉ cần đưa error log lại cho AI rồi tiếp tục chạy.

Trước đây: **Không biết → bị mắc → phải học.**

Bây giờ: **Không biết → vẫn có thể tiếp tục sang bước tiếp theo.**

Dopamine khi lấy được flag vẫn còn nguyên. Nhưng quá trình học tập mà trước đây bạn bắt buộc phải trải qua để nhận được lượng dopamine đó thì giờ đã trở thành **một lựa chọn**.

Trước đây, nếu muốn giải tốt hơn, người ta sẽ tìm kiếm kỹ thuật mới để học.
Bây giờ, có thể thứ người ta tìm đầu tiên lại là **model tốt hơn hoặc nhiều agent hơn**.
Việc flag trở nên dễ lấy hơn bản thân nó không phải điều xấu. Nhưng tôi cảm thấy **số lượng flag mà một người lấy được không còn phản ánh mức độ tăng trưởng kỹ năng của người đó nhiều như trước nữa**.

# Vậy scoreboard bây giờ đang thể hiện điều gì?

Ngay từ trước đây, thành tích CTF và năng lực bảo mật thực tế cũng chưa bao giờ hoàn toàn giống nhau. 
Khả năng giải nhanh các bài toán trong một môi trường được thiết kế sẵn rõ ràng khác với khả năng tìm lỗ hổng trong dịch vụ thực tế hoặc xây dựng một hệ thống an toàn.
Tuy nhiên, trước đây để đạt thứ hạng cao, một đội thường phải có kiến thức ở nhiều lĩnh vực, và ít nhất trong đội phải có ai đó thực sự hiểu bài mà họ đang giải.
Vì vậy, tôi từng cho rằng có một mối tương quan khá mạnh giữa **thành tích CTF và kiến thức bảo mật**.
Nhưng trong thành tích ngày nay đã xuất hiện rất nhiều yếu tố khác.

Ví dụ:

* Bạn sử dụng model nào?
* Usage limit còn bao nhiêu?
* Có thể chạy đồng thời bao nhiêu agent?
* Làm thế nào để chuyển kết quả từ một session thất bại sang session khác?
* Quản lý context cho từng bài như thế nào?

Tất cả những yếu tố này đều có thể ảnh hưởng trực tiếp đến điểm số.
Bây giờ, câu nói **“người này giỏi CTF”** cũng có thể mang nhiều ý nghĩa.

Người đó có thể giải tốt vì có kiến thức bảo mật sâu. Hoặc có thể vì người đó sử dụng AI rất tốt. Hoặc cũng có thể họ đã xây dựng một hệ thống rất tốt để tự động phân phối và quản lý nhiều agent.

Tôi không nói bất kỳ năng lực nào trong số đó là vô giá trị.

Ý tôi chỉ là **con số trên scoreboard bắt đầu đo thêm những loại năng lực khác so với trước đây**.

Theo cảm nhận của tôi, cho đến năm 2025, AI vẫn chủ yếu giống một công cụ hỗ trợ.

Nó hữu ích để hỏi hướng phân tích hoặc lấy code mẫu, nhưng cũng thường xuyên khẳng định rằng có những lỗ hổng thực tế không tồn tại hoặc tự tin đưa ra những đoạn code thậm chí không chạy được. Cuối cùng con người vẫn phải tự phân tích và sửa.

Nhưng bước sang năm 2026, tình hình đã thay đổi.
AI agent có thể: **tự mở file → chạy công cụ → sửa code → kiểm tra kết quả.**
Con người không nhất thiết phải tự thực hiện toàn bộ quá trình phân tích nữa. Đôi khi chỉ cần đưa bài toán và mục tiêu cho agent rồi thỉnh thoảng điều chỉnh hướng đi.
Vì vậy, quan niệm: **Năng lực CTF ≈ năng lực bảo mật** có lẽ sẽ ngày càng khó dùng để mô tả thực tế.

# “Trang bị” mới để tham gia CTF: gói AI đắt tiền

Khó có thể bỏ qua vấn đề chi phí. Trước đây, để bắt đầu CTF, về cơ bản chỉ cần một chiếc máy tính và môi trường Linux.

Những công cụ thường dùng như: 
* GDB,
* pwntools,
* Ghidra,
* IDA Free

phần lớn đều miễn phí.

Ngay cả học sinh cũng có thể bắt đầu với chi phí tương đối thấp, miễn là có máy tính và ý chí học.

Nhưng hiện tại, nếu muốn cạnh tranh ở nhóm thứ hạng cao, **model AI tốt và hạn mức sử dụng lớn gần như cũng trở thành một phần trong bộ trang bị cần thiết**.

ChatGPT Pro có gói 5x giá 100 USD/tháng và gói 20x giá 200 USD/tháng.
200 USD sau khi tính tỷ giá và thuế có thể lên tới khoảng 300.000 won khi thanh toán tại Hàn Quốc.
Đó chắc chắn không phải số tiền nhỏ đối với một học sinh chỉ để chơi CTF mỗi tháng.
Tất nhiên vẫn có thể giải bài bằng model miễn phí hoặc các gói rẻ hơn.
Nhưng trong một cuộc thi có thời gian giới hạn, **hiệu năng model và usage limit ảnh hưởng trực tiếp đến kết quả nhiều hơn chúng ta tưởng**.

Nếu có hạn mức lớn, khi một session đi sai hướng, bạn có thể bỏ nó ngay và mở session mới mà không phải tiếc.
Bạn có thể chạy agent trên nhiều bài cùng lúc.
Hoặc cho nhiều agent phân tích cùng một bài theo những giả thuyết khác nhau.
Nếu sử dụng thêm dịch vụ của những công ty khác hoặc API credit, chi phí còn tăng nữa.
Tất nhiên, chi nhiều tiền không có nghĩa là bài khó sẽ tự động được giải.
Nhưng **việc có thể thử nhiều lần hơn tự nó đã là một lợi thế lớn**.

Nếu một bên phải tiết kiệm usage và cẩn thận chạy một agent, trong khi bên kia có thể chạy nhiều model mạnh song song và liên tục bỏ những session thất bại để mở session mới, thì rất khó để kết quả không có sự khác biệt.

Vì vậy, đôi khi tôi cảm thấy CTF hiện nay khá giống **pay-to-win**.
Chính xác hơn thì không hẳn là dùng tiền mua đáp án, mà giống: **pay-to-try-more — trả tiền để có nhiều cơ hội thử hơn.**

Tuy nhiên, chỉ chạy thật nhiều model đắt tiền vẫn chưa đủ.
Tiền giúp tăng số lần thử.
Nhưng trong số những lần thử đó, **cái nào đáng giữ và cái nào nên bỏ vẫn cần con người quyết định**.

# Tại sao dùng cùng một AI nhưng kết quả lại khác nhau?

Không phải tất cả mọi người sử dụng model tốt tương đương nhau đều nhận được kết quả giống nhau.

Đưa cùng một file bài toán vào cùng một model:

* một người có thể lấy được flag,
* một người khác có thể đi sai hướng cho tới tận khi cuộc thi kết thúc.

Trước đây tôi từng nghĩ sự khác biệt chủ yếu nằm ở **prompt**.

Tôi viết role rất dài, chia nhỏ các bước phân tích, quy định format output và liên tục chỉnh sửa prompt dành cho CTF.

Nhưng các model gần đây đã mạnh hơn rất nhiều.

Ngay cả khi không dùng kỹ thuật phức tạp mà chỉ nói:

> “Hãy phân tích bài này và lấy flag.”

thì nó vẫn có thể tự xử lý khá nhiều thứ.

Vì vậy, hiện nay tôi cảm thấy thứ quan trọng hơn câu chữ của prompt là:

> **khả năng nhận ra khi agent đang sai.**

Dù model tốt đến đâu, với bài khó nó vẫn có thể xây dựng giả thuyết sai.

Vấn đề lớn hơn việc sai một lần là nó có thể **tiếp tục xây dựng toàn bộ quá trình phân tích tiếp theo dựa trên giả thuyết sai đó**.

Session càng dài, những phỏng đoán sai ban đầu càng dễ bị coi như sự thật.

Tôi từng thấy AI khẳng định đã phát hiện một lỗ hổng thực tế không tồn tại, sau đó chỉ liên tục sửa exploit.

Hoặc xác định một code path không thể reach được là phần cốt lõi.

Có lúc chưa hề có address leak nhưng nó đã mặc định rằng leak đã tồn tại rồi viết bước khai thác tiếp theo.

Ngay cả khi kết quả chạy không phù hợp với giả thuyết, nó cũng thường không nghi ngờ giả thuyết ban đầu mà chỉ sửa code xung quanh.

Nếu người dùng chỉ ngồi chờ kết quả, toàn bộ session có thể bị phá hỏng.

Cần kiểm tra:

* Kết quả debugging có mâu thuẫn với giả thuyết không?
* Những điều kiện tiên quyết để tấn công có thực sự được thỏa mãn không?
* Phần mà AI gọi là lỗ hổng có bằng chứng trong code hay không?

Nếu giả thuyết sai, cần có khả năng **dứt khoát cắt bỏ hướng đó**.

Nếu giả thuyết sai đã ăn quá sâu vào toàn bộ context, đôi khi tốt hơn hết là bỏ session đó và bắt đầu lại.

Nếu tiếp tục conversation cũ, model đôi khi sẽ cố gắng bảo vệ những gì nó đã khẳng định trước đó và tiếp tục lặp lại cùng một hướng.

Cuối cùng, điều quan trọng hơn việc mở thật nhiều agent là phải đánh giá được:

* mỗi session đang dựa trên giả thuyết đã được kiểm chứng đến mức nào;
* nên đưa log và file nào trước;
* kết quả phân tích nào có thể coi là sự thật;
* khi nào nên bỏ giả thuyết;
* khi nào nên giữ session;
* khi nào nên bỏ session và bắt đầu lại.

Những khả năng phán đoán này không thể chỉ có được bằng vài mẹo prompt.

Bạn phải hiểu lĩnh vực đó thì mới có thể nhìn vào log và nhận ra điều bất thường.

Bạn cũng phải có kiến thức thì mới nhận ra rằng giả thuyết AI đưa ra **về mặt kỹ thuật là vô lý**.

Với bài dễ, đôi khi chỉ cần liên tục ném file và error log cho AI — thứ thường được gọi là **slopping** — cũng đủ để flag xuất hiện.

Nhưng với bài khó, bạn phải có khả năng dừng AI lại khi nó đang chạy sai hướng và chuyển sang giả thuyết khác.

Không có kiến thức bảo mật, bạn vẫn có thể đặt câu hỏi cho AI.

Nhưng để:

> **nhận ra AI đang sai và chỉ ra hướng tiếp theo**

thì cuối cùng vẫn cần kiến thức bảo mật.

---

# Ý nghĩa của “lĩnh vực chuyên môn” trong một team

Trước đây, khi xây dựng một đội CTF, lĩnh vực chuyên môn của từng thành viên rất quan trọng.

Người ta tập hợp những người giỏi:

* Web,
* Pwnable,
* Reversing,
* Crypto,
* v.v.

Khi cuộc thi bắt đầu, mỗi người phụ trách bài thuộc lĩnh vực của mình.

Bây giờ, một người có thể chạy nhiều agent thuộc nhiều lĩnh vực cùng lúc.

Người không biết Pwnable có thể mở Pwnable agent.

Người không giỏi Web vẫn có thể giao bài Web cho AI.

Có thể nói AI đang đóng vai trò như:

* web hacker,
* pwner,
* reverser,
* và nhiều chuyên gia khác cùng lúc.

Các lĩnh vực chuyên môn chưa hoàn toàn biến mất.

Ranh giới đã mờ đi rất nhiều ở các bài dễ và trung bình, nhưng khi gặp **bức tường cuối cùng của một bài khó**, khả năng phán đoán của người đã học lĩnh vực đó lâu năm vẫn rất quan trọng.

Điều khiến tôi đặc biệt suy nghĩ là **bảng thi dành cho thanh thiếu niên**.

Phần lớn thí sinh trẻ vẫn đang trong quá trình xây dựng kiến thức.

Khi họ còn chưa có đủ kinh nghiệm chuyên môn mà đã phải cạnh tranh cùng một AI vốn biết rất nhiều tài liệu và cách sử dụng công cụ, rất dễ xảy ra tình huống:

> **thành viên giỏi giải bài nhất trong team không phải con người mà là AI.**

Đáng lẽ con người phải trưởng thành thông qua cuộc thi.

Nhưng thay vào đó, con người chỉ chuyển thông tin bài toán còn AI đảm nhận phần cốt lõi của lời giải.

Bản thân tôi cũng đang trực tiếp trải nghiệm điều này khi tham gia rất nhiều CTF gần đây.

---

# Vậy ai sẽ là người ra đề CTF trong tương lai?

Nếu những người mới bắt đầu ngay từ đầu đã giải tất cả bài bằng AI, tôi nghĩ về lâu dài có thể xuất hiện một vấn đề khác.

> **Trong tương lai, ai sẽ tạo ra những bài CTF hay?**

Trước đây tồn tại một quá trình khá tự nhiên:

**chơi CTF → nâng cao kỹ năng → thử những bài khó hơn → sau này tự nghĩ ý tưởng và ra đề.**

Khi trực tiếp giải rất nhiều bài, bạn dần hình thành cảm giác về:

* phần nào của bài thú vị;
* người chơi sẽ mắc ở đâu;
* lời giải nào là unintended solution.

Tất nhiên người ra đề cũng có thể sử dụng AI.

Thậm chí việc viết code challenge hoặc xây Docker environment có thể trở nên dễ dàng hơn.

Nhưng một bài CTF hay không phải chỉ cần generate code là xong.

Việc:

* nghĩ ra ý tưởng lỗ hổng mới,
* thiết kế intended solution,
* cân chỉnh độ khó,
* ngăn unintended solution,
* và quan trọng nhất là khiến người chơi cảm thấy **“bài này hay thật”** sau khi giải xong

là những vấn đề hoàn toàn khác.

Tôi nghĩ cảm giác đó được hình thành thông qua quá trình:

**tự giải bài → mắc rất lâu → thất bại → đọc writeup của người khác.**

Nếu người mới quen với việc chỉ nhận flag rồi submit và lập tức chuyển sang bài tiếp theo, quá trình hình thành thế hệ challenge author tiếp theo cũng có thể bị suy yếu.

AI giải được vấn đề trước mắt.

Nhưng tôi hơi lo rằng nó đồng thời có thể làm giảm cơ hội trưởng thành của những người sau này sẽ tạo ra các bài toán mới.

---

# Tôi không nói rằng chúng ta không nên dùng AI

Tuy nhiên, tôi cũng không muốn nói rằng nên cấm AI trong CTF hoặc người không sử dụng AI là “đúng đắn” hơn.

AI đã trở thành một công cụ quan trọng trong phát triển phần mềm và bảo mật.

Trong tương lai, khả năng sử dụng AI tốt chắc chắn cũng sẽ trở thành một phần của năng lực chuyên môn.

CTF cũng không phải ngoại lệ.

Nhưng trong mô hình:

> **AI + Human**

vai trò của con người không thể chỉ dừng lại ở việc **bấm nút Run**.

Con người phải có khả năng:

* xác định vấn đề;
* quyết định hướng phân tích;
* kiểm chứng giả thuyết của AI;
* chịu trách nhiệm đối với những kết quả sai.

Trong CTF, nếu code tình cờ chạy được và flag xuất hiện thì về cơ bản bạn đã thành công.

Nhưng tôi nghĩ trong thực tế không tồn tại một đáp án rõ ràng như vậy.

Bạn phải đánh giá:

* hiện tượng vừa phát hiện có thực sự là lỗ hổng không;
* có tái hiện được không;
* mức độ ảnh hưởng ra sao;
* có thực sự khai thác được trong môi trường thực tế hay không.

Nếu tin mù quáng vào phân tích sai của AI, bạn có thể làm mất thời gian của người khác hoặc thậm chí gây ra vấn đề cho hệ thống thật.

Trong CTF, đôi khi không cần kiến thức chuyên môn mà chỉ slopping cũng có thể đạt điểm cao.

Nhưng trong công việc thực tế, rất có thể bạn phải **hiểu vấn đề ở một mức nhất định rồi mới sử dụng AI**.

> **Khả năng sử dụng AI thật nhiều và khả năng chịu trách nhiệm cho output của AI là hai năng lực khác nhau.**

---

# Cần phân biệt “chế độ thi đấu” và “chế độ học tập”

Tôi cũng chưa nghĩ mình có đáp án hoàn chỉnh cho vấn đề này.

Nhưng tôi cảm thấy cần phân biệt giữa:

**Competition Mode** và **Learning Mode**.

Trong cuộc thi, bạn có thể tận dụng tối đa tất cả những công cụ được phép.

Dùng model tốt.

Chạy nhiều agent song song.

Tự động phân phối bài.

Xây dựng hệ thống chuyển kết quả phân tích thất bại cho agent khác.

Những thứ đó giờ đây cũng là một phần của năng lực CTF.

Bản thân tôi trong tương lai cũng sẽ làm như vậy.

Nhưng nếu ngay cả lúc học mà chúng ta cũng chỉ lấy flag theo cách đó rồi chuyển sang bài tiếp theo, cuối cùng thứ còn lại chỉ là **điểm số**.

Nếu AI đã giải bài cho mình, sau cuộc thi ít nhất chúng ta nên thử tự giải thích bằng lời của mình:

> **Lỗ hổng thực sự là gì?**

Có thể thử tự viết lại phần quan trọng của exploit mà agent đã tạo.

Hoặc không nhìn conversation với AI và thử tái hiện lại toàn bộ lời giải.

Đó có lẽ sẽ là một cách học hữu ích.

Đây cũng là điều tôi cảm nhận rõ nhất sau khi tham gia rất nhiều CTF.

Đạt thứ hạng cao là một điều đáng vui.

Nhưng nếu tôi không thể giải thích những bài mà mình đã “giải” khi đạt thứ hạng đó, thì rất khó nói rằng thứ hạng ấy phản ánh chính xác năng lực của tôi.

Khi AI chưa tồn tại, quá trình bị mắc ở một bài toán **buộc chúng ta phải học**.

Bây giờ có lẽ chúng ta phải **tự tạo ra sự bất tiện đó cho chính mình**.

Không sử dụng AI không đồng nghĩa với việc chắc chắn giỏi.

Ngược lại, chỉ submit câu trả lời mà AI đưa ra trong khi bản thân không hiểu và không kiểm chứng được nó cũng rất khó gọi là năng lực thực sự.

---

# Kết

Tôi không muốn đơn giản kết luận rằng:

> **“AI đã phá hỏng CTF.”**

Nhờ AI, chúng ta có thể bắt đầu phân tích những bài mà trước đây thậm chí không biết phải bắt đầu từ đâu.

Chúng ta có thể thử sức với những bài không thuộc lĩnh vực chuyên môn của mình.

AI có thể giảm những công việc lặp đi lặp lại và giúp chúng ta tập trung vào những ý tưởng khó hơn.

Bản thân tôi cũng đang hưởng rất nhiều lợi ích từ những điều đó.

Nhưng ngược lại, khi rào cản về kiến thức giảm xuống thì một rào cản mới lại xuất hiện:

> **chi phí.**

Ý nghĩa của thành tích CTF cũng trở nên phức tạp hơn trước.

Tôi vẫn sẽ tiếp tục sử dụng AI trong CTF.

Nếu có model tốt hơn xuất hiện, tôi sẽ thử nó.

Tôi cũng sẽ tiếp tục học cách quản lý các agent hiệu quả hơn.

Nhưng sau khi flag xuất hiện, tôi muốn ít nhất tự hỏi bản thân những câu sau:

> **Tôi có thể giải thích lỗ hổng của bài này không?**

> **Không có cuộc trò chuyện với AI, tôi có thể tự tái hiện lại các bước cốt lõi không?**

> **Trong lời giải này, đâu là phán đoán hoặc ý tưởng mà chính tôi đã đóng góp?**

**Lấy được flag và biến bài toán đó thành kiến thức của chính mình là hai chuyện khác nhau.**

Trước đây, ham muốn lấy flag tự nhiên dẫn chúng ta đến việc học hacking.

Bây giờ AI cho phép chúng ta bỏ qua quá trình ở giữa đó.

Vì vậy, tôi nghĩ trong tương lai, điều quan trọng hơn câu hỏi:

> **“Có nên sử dụng AI hay không?”**

sẽ là:

> **“Sau khi sử dụng AI, chúng ta giữ lại được điều gì để biến thành kiến thức và năng lực của chính mình?”**
