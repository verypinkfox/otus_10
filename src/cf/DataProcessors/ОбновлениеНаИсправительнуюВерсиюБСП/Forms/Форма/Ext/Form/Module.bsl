﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ОбработчикиСобытийФормы

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
#Если ВебКлиент ИЛИ МобильныйКлиент Тогда
	ПоказатьПредупреждение(, НСтр("ru = 'Запуск в веб-клиенте или в мобильном клиенте невозможен.
		|Запустите тонкий клиент.'"));
	Отказ = Истина;
	Возврат;
#КонецЕсли
	
	ПараметрыЗапускаЧастями = СтрРазделить(ПараметрЗапуска, ";", Ложь);
	Для Каждого Параметр Из ПараметрыЗапускаЧастями Цикл
		Если СтрНайти(Параметр, "ФайлОбновления") > 0 Тогда
			ФайлОбновления  = СокрЛП(СтрРазделить(Параметр, "=")[1]);
			ФайлОбновления = СтрЗаменить(ФайлОбновления, """", "");
		КонецЕсли;
	КонецЦикла;
	
	Если ЗначениеЗаполнено(ФайлОбновления) Тогда
		ДвоичныеДанные = Новый ДвоичныеДанные(ФайлОбновления);
		Хранилище = ПоместитьВоВременноеХранилище(ДвоичныеДанные, УникальныйИдентификатор);
		ОбновитьНаИсправительнуюВерсиюНаСервере(Хранилище);
		ЗавершитьРаботуСистемы(Ложь, Ложь);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура СформироватьФайлНастроек(Команда)
	
	ПараметрыСохранения = ФайловаяСистемаКлиент.ПараметрыСохраненияФайла();
	ПараметрыСохранения.Диалог.Заголовок  = НСтр("ru = 'Укажите имя файла настроек сравнения/объединения'");
	ПараметрыСохранения.Диалог.Фильтр     = НСтр("ru = 'Файл настроек сравнения/объединения (*.xml)|*.xml'");
	ПараметрыСохранения.Диалог.Расширение = "xml";
	ФайловаяСистемаКлиент.СохранитьФайл(Неопределено, СформироватьФайлНастроекНаСервере(), "settings.xml", ПараметрыСохранения);
	
КонецПроцедуры

&НаКлиенте
Процедура ОбновитьНаИсправительнуюВерсию(Команда)
	
	Оповещение = Новый ОписаниеОповещения("ОбновитьНаИсправительнуюВерсиюПродолжение", ЭтотОбъект);
	ПараметрыЗагрузки = ФайловаяСистемаКлиент.ПараметрыЗагрузкиФайла();
	ПараметрыЗагрузки.ИдентификаторФормы = УникальныйИдентификатор;
	ПараметрыЗагрузки.Диалог.Фильтр = НСтр("ru = 'Конфигурация информационной базы 1С:Предприятия 8 (*.cf)|*.cf'");
	ПараметрыЗагрузки.Диалог.МножественныйВыбор = Ложь;
	ПараметрыЗагрузки.Диалог.Заголовок = НСтр("ru = 'Укажите файл новой версии БСП'");
	ПараметрыЗагрузки.Диалог.ПолноеИмяФайла = НСтр("ru = '1Cv8'");
	ПараметрыЗагрузки.Диалог.Расширение     = "cf";
	ФайловаяСистемаКлиент.ЗагрузитьФайл(Оповещение, ПараметрыЗагрузки);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервере
Функция СформироватьФайлНастроекНаСервере()
	ИмяФайлаВыгрузки = ПолучитьИмяВременногоФайла("xml");
	РеквизитФормыВЗначение("Объект").СформироватьФайлНастроекСравненияОбъединения(ИмяФайлаВыгрузки);
	ДвоичныеДанные = Новый ДвоичныеДанные(ИмяФайлаВыгрузки);
	УдалитьФайлы(ИмяФайлаВыгрузки);
	Возврат ПоместитьВоВременноеХранилище(ДвоичныеДанные, УникальныйИдентификатор);
КонецФункции

&НаКлиенте
Процедура ОбновитьНаИсправительнуюВерсиюПродолжение(Результат, ДополнительныеПараметры) Экспорт
	
	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Состояние(НСтр("ru = 'Обновление на исправительную версию...'"));
	ОбновитьНаИсправительнуюВерсиюНаСервере(Результат.Хранение);
	ПоказатьПредупреждение(, НСтр("ru = 'Конфигурация успешно обновлена на исправительную версию, но не применена к базе данных.
		|Следуйте дальнейшим инструкциям.'"));
	
КонецПроцедуры

&НаСервере
Процедура ОбновитьНаИсправительнуюВерсиюНаСервере(ВыбранныйФайлОбновления)
	ИмяФайлаОбновления = ПолучитьИмяВременногоФайла("cf");
	ДвоичныеДанные = ПолучитьИзВременногоХранилища(ВыбранныйФайлОбновления); // ДвоичныеДанные
	ДвоичныеДанные.Записать(ИмяФайлаОбновления);
	
	РеквизитФормыВЗначение("Объект").ОбновитьНаИсправительнуюВерсию(ИмяФайлаОбновления);
	УдалитьФайлы(ИмяФайлаОбновления);
КонецПроцедуры

#КонецОбласти